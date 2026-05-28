GO
if object_id('[dbo].[sptblCommonControlType_Signed_DUC]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sptblCommonControlType_Signed_DUC] as select 1')
GO
ALTER PROCEDURE [dbo].[sptblCommonControlType_Signed_DUC]
    @TableName VARCHAR(256) = ''
AS
BEGIN
    -- ============================================================================
    -- PROCEDURE: sptblCommonControlType_Signed
    -- MÔ TẢ: Build HTML/JavaScript cho Grid View và các control chung dựa trên cấu hình
    -- THAM SỐ:
    --   @TableName: Tên thủ tục cần build UI (VD: 'sp_Task_MyWork_html')
    -- ============================================================================

    -- ============================================================================
    -- KHAI BÁO BIẾN
    -- ============================================================================
    DECLARE @UseLayout BIT = 0;  -- Flag để xác định có dùng Grid Layout hay không
    DECLARE @object_Id VARCHAR(MAX) = CAST(OBJECT_ID(@TableName) AS NVARCHAR(64)) -- Object ID của table

    -- ============================================================================
    -- KIỂM TRA XEM CÓ SỬ DỤNG LAYOUT HAY KHÔNG
    -- ============================================================================
    IF EXISTS (
        SELECT 1
        FROM dbo.tblCommonControlType_Signed
        WHERE TableName = @TableName
          AND Layout IS NOT NULL  -- Có Layout = Card_View
    )
    BEGIN
        SET @UseLayout = 1;
    END

    -- ============================================================================
    -- TẠO BẢNG TẠM VÀ RESET DỮ LIỆU
    -- ============================================================================
    IF OBJECT_ID('tempdb..#temptable') IS NOT NULL
        DROP TABLE #temptable

    -- Tạo UID mới cho các dòng chưa có UID
    UPDATE t
    SET [UID] = 'P' + REPLACE(CAST(NEWID() AS VARCHAR(36)), '-', '')
    FROM tblCommonControlType_Signed t
    WHERE TableName = @TableName
      AND ISNULL(t.[UID], '') = ''

    UPDATE t
    set html='',loadUI='',loadData=''
    from tblCommonControlType_Signed t
    WHERE TableName = @TableName and Type <> 'AdvancedFilterPanel'

    -- ============================================================================
    -- TẠO BẢNG TẠM #temptable
    -- Chứa toàn bộ config + columnId từ sys.columns
    -- ============================================================================
    SELECT
        ROW_NUMBER() OVER (
            ORDER BY
                CASE WHEN t.GridColumnName IS NULL THEN 0 ELSE 1 END,
                CASE WHEN t.Layout = 'Grid_View' THEN 0 ELSE 1 END,
                ISNULL(t.SortOrder, 99999),
                t.ID
        ) AS RowOrder,
        t.*,
        CAST(c.column_id AS NVARCHAR(64)) AS columnId
    INTO #temptable
    FROM dbo.tblCommonControlType_Signed t
    LEFT JOIN sys.columns c
        ON c.name = t.[ColumnName]
        AND c.object_id = OBJECT_ID(t.TableEditor)
    WHERE TableName = @TableName

    -- ============================================================================
    -- BUILD CONTROL THÔNG THƯỜNG TRƯỚC (NON-LAYOUT)
    -- Các control này được dùng cho:
    -- 1. Form thông thường (không dùng Grid/Card)
    -- 2. Hoặc được Grid/Card sử dụng (sẽ bốc vào Grid)
    -- ============================================================================

    -- Gọi các SP build control theo loại
    EXEC sp_hpaControlDate @TableName = @TableName
    EXEC sp_hpaControlTime @TableName = @TableName
    EXEC sp_hpaControlDateTime @TableName = @TableName
    EXEC sp_hpaControlPhone @TableName = @TableName
    EXEC sp_hpaControlNumber @TableName = @TableName
    EXEC sp_hpaControlMoney @TableName = @TableName
    EXEC sp_hpaControlFile @TableName = @TableName
    EXEC sp_hpaControlRichTextEditor @TableName = @TableName
    EXEC sp_hpaControlRichTextEditorPremium @TableName = @TableName
    EXEC sp_hpaControlText @TableName = @TableName
    EXEC sp_hpaControlTextArea @TableName = @TableName
    EXEC sp_hpaControlSelectBox @TableName = @TableName
    EXEC sp_hpaControlTagBox @TableName = @TableName
    EXEC sp_hpaControlSelectEmployee @TableName = @TableName
    EXEC sp_hpaControlPipeline @TableName = @TableName
    EXEC sp_hpaControlSegmented @TableName = @TableName
    EXEC sp_hpaControlCheckBox @TableName = @TableName

    UPDATE #temptable SET
        loadUI = REPLACE(loadUI, '$("#%UID%")', '$("#%UID%" + currentRecordID_%ColumnIDName2%)')
    WHERE ColumnIDName2 IS NOT NULL
      AND LTRIM(RTRIM(ColumnIDName2)) <> ''
      AND loadUI LIKE '%$("#%UID%")%';

    -- Build HTML wrapper cho các control
    UPDATE #temptable SET
    html = N'<div id="%UID%"></div>'
    WHERE [Type] IN ('hpaControlDate', 'hpaControlTime', 'hpaControlPhone',
                     'hpaControlNumber', 'hpaControlMoney', 'hpaControlDatetime', 'hpaControlFile', 'hpaControlRichTextEditor', 'hpaControlRichTextEditorPremium', 'hpaControlText', 'hpaControlTextArea', 'hpaControlSelectBox', 'hpaControlTagBox', 'hpaControlSelectEmployee', 'hpaControlPipeline')	

    -- Build loadData cho các control với logic check dòng dữ liệu (trừ Time)
    UPDATE #temptable SET
        loadData += N'
            // Smart Load: Check số dòng - nếu > 1000 thì dùng API, còn không thì load bình thường
            var spLoadDataGridName = "%DataSourceSP%";
            var isSmartLoadNeeded = false;

            // Kiểm tra xem có cần smart load hay không (chỉ cho các control có datasource)
            if (spLoadDataGridName && spLoadDataGridName.trim() !== "") {
                // Lấy data source từ window nếu đã load
                var dataSource = window["DataSource_%ColumnName%"];

                // Nếu chưa load hoặc dữ liệu trống, thì skip smart load cho lần này
                if (dataSource && Array.isArray(dataSource) && dataSource.length > 1000) {
                    isSmartLoadNeeded = true;
                }
            }

            // Nếu smart load, thì set flag để control sẽ tự động load qua API
            if (isSmartLoadNeeded) {
                window["UseAPILoad_%ColumnName%"] = true;
                return;
             }

            // Load bình thường (dữ liệu nhỏ <= 1000)

			try{	
			Instance%ColumnName%%UID%.clearValidationError();	
			}catch(e){}
            Instance%ColumnName%%UID%._suppressValueChangeAction();

			try {
				Instance%ColumnName%%UID%.option("searchValue", "");
				Instance%ColumnName%%UID%.option("text", "");
				Instance%ColumnName%%UID%.reset();
			} catch(e) {}
		
            if(obj && obj.%ColumnName% != null) Instance%ColumnName%%UID%.option("value", obj.%ColumnName%);
            else Instance%ColumnName%%UID%.option("value", "");            						

			Instance%ColumnName%%UID%._resumeValueChangeAction();		
			
		
        '
    WHERE [Type] IN ('hpaControlDate', 'hpaControlPhone', 'hpaControlNumber',
                     'hpaControlMoney', 'hpaControlText', 'hpaControlTextArea',
                     'hpaControlSelectBox', 'hpaControlSelectEmployee', 'hpaControlPipeline')
    UPDATE #temptable SET
        loadData = N'
            // Pipeline: không có smart load vì datasource đã load khi khởi tạo
            // Chỉ cần set currentID vào instance để render lại đúng bước

            if (typeof Instance%ColumnName%%UID% !== "undefined" && Instance%ColumnName%%UID%) {
                Instance%ColumnName%%UID%._suppressValueChangeAction();
            }

            if (typeof obj !== "undefined" && obj && obj.%ColumnName% !== undefined && obj.%ColumnName% !== null) {
                // Có dữ liệu → set ID bước hiện tại
                typeof Instance%ColumnName%%UID% !== "undefined"
                    ? Instance%ColumnName%%UID%.option("value", obj.%ColumnName%)
                    : "";
            } else {
                // Không có dữ liệu → reset về null (không chọn bước nào)
                typeof Instance%ColumnName%%UID% !== "undefined"
                    ? Instance%ColumnName%%UID%.option("value", null)
          : "";
            }

            if (typeof Instance%ColumnName%%UID% !== "undefined" && Instance%ColumnName%%UID%) {
                Instance%ColumnName%%UID%._resumeValueChangeAction();
            }
        '
    WHERE [Type] = 'hpaControlPipeline';

    UPDATE #temptable SET
        loadData = N'
            // Smart Load: Check số dòng - nếu > 1000 thì dùng API, còn không thì load bình thường
            var spLoadDataGridName = "%DataSourceSP%";
            var isSmartLoadNeeded = false;

            if (spLoadDataGridName && spLoadDataGridName.trim() !== "") {
                var dataSource = window["DataSource_%ColumnName%"];
                if (dataSource && Array.isArray(dataSource) && dataSource.length > 1000) {
                    isSmartLoadNeeded = true;
                }
            }

            if (isSmartLoadNeeded) {
                window["UseAPILoad_%ColumnName%"] = true;
                return;
            }

            // Load bình thường cho TagBox - LUÔN CHUẨN HÓA THÀNH MẢNG
            Instance%ColumnName%%UID%._suppressValueChangeAction();

            var rawValue = obj.%ColumnName%;
            var normalizedValue;			

		
			if (Array.isArray(rawValue)) {
                normalizedValue = rawValue;
            } else if (typeof rawValue === ''string'' && rawValue.trim() !== '''') {
                // Tách mảng và giữ nguyên giá trị chuỗi, chỉ trim khoảng trắng
                normalizedValue = rawValue.split('','').map(v => v.trim()).filter(v => v !== '''');
                normalizedValue = normalizedValue.map(v => {
                    return (v !== '''' && !isNaN(v)) ? Number(v) : v;
                });

				//else if (rawValue.includes("&")){
				//	  normalizedValue = rawValue.split("&")
				//	.map(v => Number(v.trim()))
				//	.filter(v => !isNaN(v));




				//}
			}
			else {
				normalizedValue = [];
			}
			
            Instance%ColumnName%%UID%.option("value", normalizedValue);
            Instance%ColumnName%%UID%._resumeValueChangeAction();
        '
    WHERE [Type] IN ('hpaControlTagBox')

    UPDATE #temptable SET
        loadData = N'
            // Smart Load logic (giữ nguyên logic check > 1000 dòng)
            var spLoadDataGridName = "%DataSourceSP%";
            var isSmartLoadNeeded = false;

            if (spLoadDataGridName && spLoadDataGridName.trim() !== "") {
                var dataSource = window["DataSource_%ColumnName%"];
                if (dataSource && Array.isArray(dataSource) && dataSource.length > 1000) {
                    isSmartLoadNeeded = true;
                }
            }

            if (isSmartLoadNeeded) {
                window["UseAPILoad_%ColumnName%"] = true;
                return;
            }

            // Load logic cho DateTime: Phải ép kiểu new Date để hiện đúng giờ
            Instance%ColumnName%%UID%._suppressValueChangeAction();
            if (obj.%ColumnName%) {
                // Ép kiểu chuỗi SQL sang JS Date Object
                Instance%ColumnName%%UID%.option("value", new Date(obj.%ColumnName%));
            } else {
                Instance%ColumnName%%UID%.option("value", null);
            }
            Instance%ColumnName%%UID%._resumeValueChangeAction();
        '
    WHERE [Type] = 'hpaControlDateTime'

    UPDATE #temptable SET
        loadData = N'
        window["DataSource_%ColumnName%"] = window["DataSource_%ColumnName%"] || [];
            AjaxHPAParadise({
                data: {
                    name: "%DataSourceSP%",
                    param: ["LoginID", LoginID, "IdentityID", currentRecordID_%ColumnIDName%]
                },
                success: function (res) {
                    const json = typeof res === "string" ? JSON.parse(res) : res;
                    window["DataSource_%ColumnName%"] = (json.data && json.data[0]) || [];
                    Instance%ColumnName%%UID%.option("dataSource", window["DataSource_%ColumnName%"]);
                }
            });'
    WHERE [Type] = 'hpaControlFile'

    -- Build loadData đặc biệt cho Time (cần format khác) với smart load
    UPDATE #temptable SET
 loadData = N'
            // Smart Load: Check số dòng - nếu > 1000 thì dùng API, còn không thì load bình thường
            var spLoadDataGridName = "%DataSourceSP%";
            var isSmartLoadNeeded = false;

            // Kiểm tra xem có cần smart load hay không
            if (spLoadDataGridName && spLoadDataGridName.trim() !== "") {
                var dataSource = window["DataSource_%ColumnName%"];

                if (dataSource && Array.isArray(dataSource) && dataSource.length > 1000) {
                    isSmartLoadNeeded = true;
                }
            }

            // Nếu smart load, set flag và return
            if (isSmartLoadNeeded) {
                window["UseAPILoad_%ColumnName%"] = true;
                return;
            }

            // Load bình thường (dữ liệu nhỏ <= 1000)
            Instance%ColumnName%%UID%._suppressValueChangeAction();
            Instance%ColumnName%%UID%.option("value", obj.%ColumnName% ? new Date("1970/01/01 " + obj.%ColumnName%) : null);
            Instance%ColumnName%%UID%._resumeValueChangeAction();
        '
    WHERE [Type] = 'hpaControlTime'

    UPDATE #temptable SET
        loadData = N'
            // Smart Load: Check số dòng - nếu > 1000 thì dùng API, còn không thì load bình thường
            var spLoadDataGridName = "%DataSourceSP%";
            var isSmartLoadNeeded = false;

            // Kiểm tra xem có cần smart load hay không (chỉ cho các control có datasource)
    if (spLoadDataGridName && spLoadDataGridName.trim() !== "") {
                // Lấy data source từ window nếu đã load
                var dataSource = window["DataSource_%ColumnName%"];

                // Nếu chưa load hoặc dữ liệu trống, thì skip smart load cho lần này
                if (dataSource && Array.isArray(dataSource) && dataSource.length > 1000) {
                    isSmartLoadNeeded = true;
                }
            }

            // Nếu smart load, thì set flag để control sẽ tự động load qua API
            if (isSmartLoadNeeded) {
                window["UseAPILoad_%ColumnName%"] = true;
                return;
            }
            if (obj && obj.%ColumnName%) {
             var retryCount_%ColumnName%%UID% = 0;
                var fillDataInterval_%ColumnName%%UID% = setInterval(function() {
                    /* Kiểm tra xem biến rteObj đã tồn tại và chưa bị destroy chưa */
                    /* Lưu ý: ''undefined'' là do escaping trong SQL */
                    if (typeof rteObj_%ColumnName%%UID% !== ''undefined'' &&
                        rteObj_%ColumnName%%UID% &&
                        !rteObj_%ColumnName%%UID%.isDestroyed) {

                        /* --- BƯỚC 1: XỬ LÝ CHUỖI HTML TRƯỚC KHI GÁN --- */
                        var rawHtml = obj.%ColumnName%;


                        var safeHtml = rawHtml.replace(/<img([^>]*?)src=["'']([^"''+]+)["'']([^>]*?)>/gi, function(match, p1, srcVal, p2) {
                            /* Dùng nháy kép " cho chuỗi JS để không bị lỗi SQL */
                            if (srcVal.indexOf("http") === 0 || srcVal.indexOf("data:") === 0 || srcVal.indexOf("blob:") === 0) {
                                return match;
                            }
                            /* Dùng Template Literal (dấu huyền) để tạo chuỗi an toàn */
                            return `<img ${p1} src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=" data-original-url="${srcVal}" ${p2}>`;
                        });

                        /* --- BƯỚC 2: GÁN HTML SẠCH VÀO EDITOR --- */
                        rteObj_%ColumnName%%UID%.value = safeHtml;
                        rteObj_%ColumnName%%UID%.dataBind();

           /* --- BƯỚC 3: CONVERT TỪ DATA-ORIGINAL-URL SANG BLOB --- */
                        try {
                            var rteElement = rteObj_%ColumnName%%UID%.inputElement;

var imgs = rteElement.querySelectorAll(''img'');

   for (var i = 0; i < imgs.length; i++) {
                                var img = imgs[i];

                                var realPath = img.getAttribute(''data-original-url'');

                                if (realPath) {
                                    (function(targetImg, targetPath){
                                        convertPathToBlobUrl(targetPath).then(function(newBlobUrl){
                                            if (newBlobUrl) {
                                                /* ''src'' -> '''' */
                                                targetImg.setAttribute(''src'', newBlobUrl);
                                            }
                                        });
                                    })(img, realPath);
                                }
                            }
                        } catch(ex) { console.log(ex); }

                        clearInterval(fillDataInterval_%ColumnName%%UID%);
                    } else {
                        retryCount_%ColumnName%%UID%++;
                        if (retryCount_%ColumnName%%UID% > 50) { clearInterval(fillDataInterval_%ColumnName%%UID%); }
                    }
                }, 200);
            } else {
                /* Xử lý khi dữ liệu null/rỗng */
   if (typeof rteObj_%ColumnName%%UID% !== ''undefined'' && rteObj_%ColumnName%%UID%) {
  rteObj_%ColumnName%%UID%.value = "";
                    rteObj_%ColumnName%%UID%.dataBind();
}
          }

            Instance%ColumnName%%UID%.innerText = obj.%ColumnName% || "";

        '
    WHERE [Type] = 'hpaControlRichTextEditor'


    UPDATE #temptable SET
        loadData = N'
            // Smart Load
            var spLoadDataGridName = "%DataSourceSP%";
            var isSmartLoadNeeded = false;
            if (spLoadDataGridName && spLoadDataGridName.trim() !== "") {
                var dataSource = window["DataSource_%ColumnName%"];
                if (dataSource && Array.isArray(dataSource) && dataSource.length > 1000) isSmartLoadNeeded = true;
            }
            if (isSmartLoadNeeded) { window["UseAPILoad_%ColumnName%"] = true; return; }

            // Logic mới: Chạy thẳng, không cần chờ loop vì Premium init nhanh
            if (typeof rteObj_%ColumnName%%UID% !== "undefined" && rteObj_%ColumnName%%UID%) {
                var rawHtml = (typeof obj !== "undefined" && obj) ? (obj.%ColumnName% || "") : "";

                // 1. Xử lý Safe HTML cho ảnh
                var safeHtml = rawHtml.replace(/<img([^>]*?)src=["'']([^"''+]+)["'']([^>]*?)>/gi, function(match, p1, srcVal, p2) {
                    if (srcVal.indexOf("http") === 0 || srcVal.indexOf("data:") === 0 || srcVal.indexOf("blob:") === 0) return match;
                    return `<img ${p1} src="data:image/gif;base64,R0lGODlhAQABAAD/ACwAAAAAAQABAAACADs=" data-original-url="${srcVal}" ${p2}>`;
                });

                // 2. Gọi setHtml (Hàm này sẽ tự động bọc div class="editor-block" nếu bạn đã cập nhật ở bước trước)
                rteObj_%ColumnName%%UID%.setHtml(safeHtml);

                // 3. Xử lý load ảnh (Async) - Giữ nguyên logic của bạn
                setTimeout(function() {
                    try {
                        var editorDiv = document.getElementById("editor-%UID%");
                        if (editorDiv) {
                            var imgs = editorDiv.querySelectorAll("img");
                            for (var i = 0; i < imgs.length; i++) {
                                var img = imgs[i];
                                var realPath = img.getAttribute("data-original-url");
                                if (realPath) {
               (function(targetImg, targetPath){
                                        convertPathToBlobUrl(targetPath).then(function(newBlobUrl){
                        if (newBlobUrl) {
          targetImg.setAttribute("src", newBlobUrl);
                                                targetImg.removeAttribute("data-original-url");
                                            }
                                        });
                                    })(img, realPath);
                                }
                            }
                        }
                    } catch(ex) { console.warn("Image load error:", ex); }
                }, 50);
            }

            // 4. Cập nhật fallback (Đảm bảo giá trị .value của Instance cũng được chuẩn hóa)
            if(typeof Instance%ColumnName%%UID% !== "undefined") {
                 // Lấy ngược lại HTML đã được editor chuẩn hóa để gán vào value
                 Instance%ColumnName%%UID%.value = rteObj_%ColumnName%%UID%.getHtml();
            }
        '
    WHERE [Type] = 'hpaControlRichTextEditorPremium'

    -- ============================================================================
    -- GRID VIEW LAYOUT
    -- Build UI cho Grid View (dạng bảng với các cột động)
    -- ============================================================================
    IF EXISTS (SELECT 1 FROM #temptable WHERE Layout = 'Grid_View')
    BEGIN
        -- ========================================================================
        -- LẤY THÔNG TIN CƠ BẢN CỦA GRID
        -- ========================================================================
   DECLARE @PKColumnNameGrid VARCHAR(100) = 'ID'

        -- Lấy tên cột Primary Key từ config
        SELECT TOP 1 @PKColumnNameGrid = ColumnIDName
        FROM #temptable
        WHERE ColumnIDName IS NOT NULL

        SET @PKColumnNameGrid = ISNULL(@PKColumnNameGrid, 'ID')

        DECLARE @tableId NVARCHAR(64) = CAST(OBJECT_ID(@TableName) AS NVARCHAR(64))
        DECLARE @gridColumns NVARCHAR(MAX) = N''
        DECLARE @IsSimpleViewGrid BIT = 0  -- chỉ xem
        DECLARE @CurrentGridType VARCHAR(50) = ''  -- Lưu type của grid hiện tại

        -- ========================================================================
        -- BUILD GRID CONTAINER CHO TẤT CẢ CÁC GRID
        -- Sử dụng CURSOR để lặp qua từng GridColumnName
        -- ========================================================================
        DECLARE @GridColumnsCursor CURSOR;
        DECLARE @GridColumnName VARCHAR(100);

        SET @GridColumnsCursor = CURSOR FOR
        SELECT DISTINCT ColumnName
        FROM #temptable
        WHERE Layout = 'Grid_View' AND Type IN ('hpaControlGrid', 'hpaControlGrid_Duc');

        OPEN @GridColumnsCursor;
        FETCH NEXT FROM @GridColumnsCursor INTO @GridColumnName;
        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- RESET @gridColumns cho mỗi Grid
            SET @gridColumns = N'';

            -- Kiểm tra Type của Grid (hpaControlGrid_Duc = simple view)
            SELECT TOP 1
                @CurrentGridType = Type,
                @PKColumnNameGrid = ISNULL(ColumnIDName, '')
            FROM #temptable
            WHERE Layout = 'Grid_View'
                AND ColumnName = @GridColumnName
                AND Type IN ('hpaControlGrid', 'hpaControlGrid_Duc')
            SET @IsSimpleViewGrid = CASE WHEN @CurrentGridType = 'hpaControlGrid_Duc' THEN 1 ELSE 0 END

            -- DROP và TẠO LẠI #GridColumnsGrouped cho Grid hiện tại
            IF OBJECT_ID('tempdb..#GridColumnsGrouped') IS NOT NULL
                DROP TABLE #GridColumnsGrouped;

            -- BUILD COLUMNS CHỈ CHO GRID HIỆN TẠI (filter theo @GridColumnName)
            SELECT
                N'' + ISNULL(col.TableEditor, '') AS tableId,
                ISNULL(col.ColumnIDName, '') AS ColumnIDName,
                ISNULL(col.ColumnIDName2, '') AS ColumnIDName2,
                ISNULL(col.DataSourceSP, '') AS DataSourceSP,
                col.GridColumnName,
          col.ColumnName AS DataFieldName,
                col.[Type] AS ControlType,
                ISNULL(col.DisplayName, col.GridColumnName) AS DisplayName,
                ISNULL(col.GridWidth, 150) AS GridWidth,
                ISNULL(col.AllowSorting, 1) AS AllowSorting,
 ISNULL(col.AllowFiltering, 1) AS AllowFiltering,
                MIN(col.SortOrder) as SortOrder,
                col.GroupIndex,
                MIN(col.ID) AS ColumnOrderID,
            MAX(CASE WHEN col.ReadOnly = 1 THEN col.loadUI ELSE NULL END) AS loadUI_View,
 MAX(CASE WHEN col.ReadOnly = 0 THEN col.loadUI ELSE NULL END) AS loadUI_Edit,
                MAX(CASE WHEN col.ReadOnly = 0 AND col.Type IS NOT NULL THEN 1 ELSE 0 END) AS HasEditMode
            INTO #GridColumnsGrouped
            FROM #temptable col
            WHERE col.GridColumnName = @GridColumnName AND col.TableName = @TableName
                AND col.Layout = 'Grid_View'
           AND (col.Type IS NOT NULL OR (col.Type IS NULL AND col.ColumnName IS NOT NULL))
            GROUP BY
                col.SortOrder,
                col.TableName,
                col.TableEditor,
                col.DataSourceSP,
                col.ColumnIDName,
                col.ColumnIDName2,
                col.GridColumnName,
                col.ColumnName,
                col.DisplayName,
                col.GridWidth,
                col.AllowSorting,
col.AllowFiltering,
                col.[Type],
                col.GroupIndex;
				-- select 1
            -- BUILD @gridColumns CHO GRID HIỆN TẠI

            -- Thêm column Detail ở đầu nếu có multi select
            DECLARE @HasMultiSelect BIT = 0;
    SELECT @HasMultiSelect = ISNULL(IsMultiSelectRowGrid, 0)
            FROM #temptable
            WHERE Layout = 'Grid_View' AND ColumnName = @GridColumnName AND Type IN ('hpaControlGrid', 'hpaControlGrid_Duc');

            IF @HasMultiSelect = 1
            BEGIN
                SET @gridColumns += N'
                {
                    dataField: "_detailAction",
                    caption: "",
                    width: 50,
                    alignment: "center",
                    allowSorting: false,
                    allowFiltering: false,
                    allowReordering: false,
                    allowResizing: false,
                    fixed: true,
                    cellTemplate: function(container, options) {
                        $("<div>").addClass("detail-btn").html(''<i class="fa fa-eye" style="cursor: pointer; color: #007bff; font-size: 14px;"></i>'').appendTo(container);
                    }
                },';
            END

            -- Nếu IsSimpleViewGrid = 1 → chỉ dùng text thuần (nhẹ nhất)
            IF @IsSimpleViewGrid = 1

            BEGIN
                SELECT @gridColumns += N'
                {
                    dataField: "' + DataFieldName + N'",
                    caption: "' + REPLACE(DisplayName, '"', '\"') + N'",
                 width: ' +
                    CASE
                        WHEN ISNUMERIC(GridWidth) = 1 AND GridWidth NOT LIKE '%[^0-9]%'
                        THEN CAST(GridWidth AS VARCHAR(10))
                        ELSE '''' + CAST(GridWidth AS VARCHAR(10)) + ''''
                    END
                + N',
                    alignment: "left",
                    minWidth: 80,
                    maxWidth: 400,
                    allowSorting: ' + CASE WHEN AllowSorting = 1 THEN 'true' ELSE 'false' END + N',
                    allowFiltering: ' + CASE WHEN AllowFiltering = 1 THEN 'true' ELSE 'false' END + N',
                    ' +
                    CASE WHEN GroupIndex IS NOT NULL
                        THEN 'groupIndex: ' + CAST(GroupIndex AS VARCHAR(10)) + N', '
                        ELSE ''
           END
                    +
                    -- Simple View: Chỉ render text với format cơ bản
CASE
    WHEN ControlType IN ('hpaControlDate', 'hpaControlDateTime', 'hpaControlTime') THEN
                            N'cellTemplate: function(cellElement, cellInfo){
                                const val = cellInfo.value;
                     if (!val || val === "") {
                                    $("<div>").addClass("dx-placeholder").text("").appendTo(cellElement);
                 return;
            }
  const d = new Date(val);
  let text = "";' +

                                CASE
                                    WHEN ControlType = 'hpaControlDate' THEN N' text = DevExpress.localization.formatDate(d, "dd/MM/yyyy");'
            WHEN ControlType = 'hpaControlTime' THEN N' text = DevExpress.localization.formatDate(d, "HH:mm");'
                                    WHEN ControlType = 'hpaControlDateTime' THEN N' text = DevExpress.localization.formatDate(d, "dd/MM/yyyy HH:mm");'
                                    ELSE N''
                                END + N'
                                $("<div>").text(text).appendTo(cellElement);
                            },
                            allowEditing: false,'
                        WHEN ControlType = 'hpaControlSelectEmployee' THEN
                            N'lookup: {
                                dataSource: window["DataSource_' + DataFieldName + N'"] || [],
                                valueExpr: "ID",
                                displayExpr: "Name"
                            },
                            cellTemplate: function(cellElement, cellInfo){
                                const val = cellInfo.value;
                                if (!val || val === "") {
                                    $("<div>").addClass("dx-placeholder").text("").appendTo(cellElement);
                                    return;
                                }

                                // Parse IDs từ chuỗi (ID,ID,ID hoặc single ID)
                                const ids = String(val).split(",").map(id => id.trim()).filter(id => id);
                                const ds = window["DataSource_' + DataFieldName + N'"] || [];

                                // Initialize cache nếu chưa có
                                if (!window.GlobalEmployeeAvatarCache) {
                                    window.GlobalEmployeeAvatarCache = {};
                                }

                                // Tính động số avatar có thể hiển thị dựa trên cell width
                                let cellWidth = cellElement.offsetWidth || 150;
                                // Trừ padding và gap
                                const availableWidth = cellWidth - 8; // 4px left + 4px right padding
                                const avatarSize = 28; // width + border 2*2
                                const overlapMargin = 10; // -10px margin-left
                                const firstAvatarWidth = avatarSize;
                                const eachNextAvatarWidth = avatarSize - overlapMargin; // 18px

                                // Tính max avatars có thể fit vào cell
                                let maxVisibleAvatars = 1;
                                if (availableWidth > firstAvatarWidth) {
                                    const remainingWidth = availableWidth - firstAvatarWidth;
                                    maxVisibleAvatars = 1 + Math.floor(remainingWidth / eachNextAvatarWidth);
                                }
                                maxVisibleAvatars = Math.max(1, Math.min(maxVisibleAvatars, ids.length));

                                // Tạo container stack avatar
                                const $stackContainer = $("<div>")
                                    .css({
"display": "flex",
      "align-items": "center",
                  "gap": "2px",
  "position": "relative"
                                    });

                                // Render avatars tối đa (maxVisibleAvatars - 1 nếu cần show "+X")
                     const showCountBadge = ids.length > maxVisibleAvatars;
                                const visibleCount = showCountBadge ? maxVisibleAvatars - 1 : maxVisibleAvatars;

       ids.slice(0, visibleCount).forEach((empId, index) => {
                                    const employee = ds.find(x => x.id == empId || x.ID == empId);
                            const empName = employee ? (employee.Name) : "";
                             const avatarUrl = window.GlobalEmployeeAvatarCache[empId] || "";

                                    let $img;
             if (avatarUrl) {
          // Avatar đã trong cache
                         $img = $("<img>")
                            .attr("src", avatarUrl)
                           .attr("title", empName)
                            .attr("data-emp-id", empId)
                                            .css({
                                                "width": "28px",
                                                "height": "28px",
                                                "border-radius": "50%",
                                                "border": "2px solid white",
                                                "margin-left": index > 0 ? "-10px" : "0",
                                                "cursor": "pointer",
                                                "z-index": ids.length - index,
                                                "box-shadow": "0 0 4px rgba(0,0,0,0.1)",
                                                "flex-shrink": 0
                                            });
                                    } else {

                                        $img = $("<img>")
                                            .attr("src", ImageParadiseDefault)
                                            .attr("title", empName)
                                            .attr("data-emp-id", empId)
                                            .attr("data-%ColumnName%", empId)
                                            .css({
                                                "width": "28px",
                                                "height": "28px",
                                                "border-radius": "50%",
                                                "border": "2px solid white",
                                                "margin-left": index > 0 ? "-15px" : "0",
                                                "cursor": "pointer",
                                                "z-index": ids.length - index,
                                                "box-shadow": "0 0 4px rgba(0,0,0,0.1)",
                                                "flex-shrink": 0
                                            });
                                        // Load avatar async
                                        (function(empIdParam, $img, empNameParam, employeeObj, indexParam) {
                                            // Lấy paramImg và storeImgName từ DataSource
                                            const paramImg = employeeObj && employeeObj.paramImg ? employeeObj.paramImg : empIdParam;
                                            const storeImgName = employeeObj && employeeObj.storeImgName ? employeeObj.storeImgName : "sp_GetEmployeeAvatar";

                                            AjaxHPAParadise({
                                                data: {
                                                    name: storeImgName,
                                                    param: decodeURIComponent(paramImg)
                                                },
       xhrFields: { responseType: "blob" },
     cache: true,
   success: function (blob) {
                                                    try {
                  // Kiểm tra blob có đúng kiểu không
                                                        let blobUrl = "";
                                                        if (blob instanceof Blob) {
                                                            blobUrl = URL.createObjectURL(blob);
                                                        } else if (blob instanceof ArrayBuffer) {
 const newBlob = new Blob([blob], { type: "image/jpeg" });
               blobUrl = URL.createObjectURL(newBlob);
                          } else if (typeof blob === "string" && blob.startsWith("blob:")) {
  blobUrl = blob;
                                                        }
                                                  if (blobUrl) {
                                                            // Lưu vào cache memory
                                                            window.GlobalEmployeeAvatarCache[empIdParam] = blobUrl;

                                                            // Gán blob URL trực tiếp vào img tag (không cần replaceWith)
                                                            $img.attr("src", blobUrl);
                                                            // Cập nhật tất cả img với data-%ColumnName% tương ứng
                                                            $("img[data-%ColumnName%=''" + empIdParam + "'']").each(function () {
                                                                $(this).attr("src", blobUrl);
                                                            });
                                                        }
                                                    } catch(ex) {
                                                        console.warn("Error loading avatar for " + empIdParam, ex);
                                                    }
                                                },
                                                error: function(err) {
                                                    console.warn("Failed to load avatar for " + empIdParam, err);
                                                }
                                            });
                                        })(empId, $img, empName, employee, index);
                                    }

                                    $stackContainer.append($img);
                                });

                                // Add "+X" badge nếu còn avatar không hiển thị
                                if (showCountBadge) {
                                    const remainingCount = ids.length - visibleCount;
                                    const $count = $("<div>")
                                        .attr("title", "+" + remainingCount + " more")
                                        .css({
                                            "width": "28px",
                                            "height": "28px",
                                            "border-radius": "50%",
                                            "background": "#e8e8e8",
                                            "display": "flex",
                                            "align-items": "center",
                                            "justify-content": "center",
                                            "font-size": "11px",
                                            "font-weight": "bold",
                                            "border": "2px solid white",
                                            "margin-left": "-10px",
                                            "z-index": 0,
                                            "color": "#666",
       "cursor": "default",
                                            "flex-shrink": 0
        })
              .text("+" + remainingCount);
      $stackContainer.append($count);
                                }

  $stackContainer.appendTo(cellElement);
              },
        allowEditing: false,'
                   WHEN ControlType IN ('hpaControlSelectBox', 'hpaControlTagBox') THEN
                            N'lookup: {
                                dataSource: window["DataSource_' + DataFieldName + N'"] || [],
                                valueExpr: "ID",
                                displayExpr: "Name"
                            },
                            cellTemplate: function(cellElement, cellInfo){

                const val = cellInfo.value;

          if (val === null || val === undefined || val === "") {
                            $("<div>").addClass("dx-placeholder").text("").appendTo(cellElement);
                                    return;
                               }
        const ds = window["DataSource_' + DataFieldName + N'"];

        if (ds && Array.isArray(ds)) {
                                    const f = ds.find(x => x.id == val || x.ID == val);
                                    if (f) {
                                        $("<div>").text(f.Text || f.Name || "").appendTo(cellElement);
 return;
      }
}

   $("<div>").text(val).appendTo(cellElement);
              },
                            allowEditing: false,'
                        WHEN ControlType = 'hpaControlLink' THEN
                            N'cellTemplate: function(cellElement, cellInfo){
                                const val = cellInfo.value;
                                if (!val || val === "") {
                                    $("<div>").addClass("dx-placeholder").text("").appendTo(cellElement);
                                    return;
                                }
                                const href = (val.indexOf("http") === 0) ? val : "https://" + val;
                                $("<a>")
                                    .attr("href", href)
                                    .attr("target", "_blank")
                                    .attr("rel", "noopener noreferrer")
                                    .text(val)
                                    .css({"color": "#0d6efd", "text-decoration": "underline", "cursor": "pointer"})
                                    .on("click", function(e){ e.stopPropagation(); })
                                    .appendTo(cellElement);
                            },
                            allowEditing: false,'
                        WHEN ControlType = 'hpaControlCheckBox' THEN
                            N'cellTemplate: function(cellElement, cellInfo){
                                const checked = cellInfo.value == 1 || cellInfo.value === true;
                                const color = getComputedStyle(document.documentElement).getPropertyValue("--paradise-color-checkbox").trim() || "#198754";
                                const $icon = $("<div>").css({
                                    display: "flex",
                                    alignItems: "left",
                                    justifyContent: "left",
                                    height: "100%"
                                });
                                if (checked) {
                                    $icon.html(
                                        "<svg width=''18'' height=''18'' viewBox=''0 0 18 18'' fill=''none'' xmlns=''http://www.w3.org/2000/svg''>" +
                                        "<rect width=''18'' height=''18'' rx=''4'' fill=''" + color + "''/>" +
                                        "<polyline points=''4,9 7.5,13 14,5'' stroke=''#fff'' stroke-width=''2.2'' stroke-linecap=''round'' stroke-linejoin=''round'' fill=''none''/>" +
                                        "</svg>"
                           );
         } else {
    $icon.html(
                                        "<svg width=''18'' height=''18'' viewBox=''0 0 18 18'' fill=''none'' xmlns=''http://www.w3.org/2000/svg''>" +
                                        "<rect width=''17'' height=''17'' x=''0.5'' y=''0.5'' rx=''3.5'' stroke=''" + color + "'' stroke-opacity=''0.45'' fill=''none''/>" +
                                        "</svg>"
                                    );
                                }
                                $icon.appendTo(cellElement);
                            },
                            allowEditing: false,'
                        ELSE

                      N'cellTemplate: function(cellElement, cellInfo){
                                const val = cellInfo.value;
                                if (val === undefined || val === null || val === "") {
                                    $("<div>").addClass("dx-placeholder").text("").appendTo(cellElement);
                                    return;
                                }
                                $("<div>").text(val).appendTo(cellElement);
                            },
                            allowEditing: false,'
                    END
                    + N'
                },
                    '
   FROM #GridColumnsGrouped
                ORDER BY SortOrder,ColumnOrderID;
            END
            ELSE
            BEGIN
                -- GRID THƯỜNG (có edit, control phức tạp)
                SELECT @gridColumns += N'
 {
                    dataField: "' + DataFieldName + N'",
caption: "' + REPLACE(DisplayName, '"', '\"') + N'",
                    width: ' + CAST(GridWidth AS VARCHAR(10)) + N',
                    allowSorting: ' + CASE WHEN AllowSorting = 1 THEN 'true' ELSE 'false' END + N',
                    allowFiltering: ' + CASE WHEN AllowFiltering = 1 THEN 'true' ELSE 'false' END + N',
                    ' +
                    CASE WHEN GroupIndex IS NOT NULL
                        THEN 'groupIndex: ' + CAST(GroupIndex AS VARCHAR(10)) + N', '
                        ELSE ''

              END
                    +
                    CASE
                        WHEN ControlType IS NULL THEN
                            N'cellTemplate: function(cellElement, cellInfo){
                      const val = cellInfo.value;

                            if (val === undefined || val === null || val === "") {
                                $("<div>").addClass("dx-placeholder").text("").appendTo(cellElement);
                                return;
 }


                         $("<div>").text(val).appendTo(cellElement);
},'

                    WHEN ControlType = 'hpaControlLink' THEN
                  N'cellTemplate: function(cellElement, cellInfo){
      const val = cellInfo.value;
                            if (!val || val === "") {
                                $("<div>").addClass("dx-placeholder").text("").appendTo(cellElement);
                                return;
                            }
                            const href = (val.indexOf("http") === 0) ? val : "https://" + val;
                            $("<a>")
                                .attr("href", href)
                                .attr("target", "_blank")
                                .attr("rel", "noopener noreferrer")
                                .text(val)
                                .css({"color": "#0d6efd", "text-decoration": "underline", "cursor": "pointer"})
                                .on("click", function(e){ e.stopPropagation(); })
                                .appendTo(cellElement);
                        },
                        allowEditing: false,'
                    WHEN ControlType = 'hpaControlCheckBox' THEN
                        N'cellTemplate: function(cellElement, cellInfo){
   const checked = cellInfo.value == 1 || cellInfo.value === true;
                    const color = getComputedStyle(document.documentElement).getPropertyValue("--paradise-color-checkbox").trim() || "#198754";
                            const $icon = $("<div>").css({
                                display: "flex",
                                alignItems: "center",
                                justifyContent: "center",
                                height: "100%"
                            });
                            if (checked) {
                                $icon.html(
                                    "<svg width=''18'' height=''18'' viewBox=''0 0 18 18'' fill=''none'' xmlns=''http://www.w3.org/2000/svg''>" +
                                    "<rect width=''18'' height=''18'' rx=''4'' fill=''" + color + "''/>" +
                                    "<polyline points=''4,9 7.5,13 14,5'' stroke=''#fff'' stroke-width=''2.2'' stroke-linecap=''round'' stroke-linejoin=''round'' fill=''none''/>" +
                                    "</svg>"
                                );
                            } else {
                                $icon.html(
                                    "<svg width=''18'' height=''18'' viewBox=''0 0 18 18'' fill=''none'' xmlns=''http://www.w3.org/2000/svg''>" +
                                    "<rect width=''17'' height=''17'' x=''0.5'' y=''0.5'' rx=''3.5'' stroke=''" + color + "'' stroke-opacity=''0.45'' fill=''none''/>" +
                                    "</svg>"
                                );
                            }
                            $icon.appendTo(cellElement);
                        },
                        allowEditing: false,'
                    WHEN ControlType NOT IN (
         'hpaControlDateTime',
                        'hpaControlDate',
                        'hpaControlTime',
                        'hpaControlSelectEmployee',
                        'hpaControlLink'
                    ) THEN
                        N'lookup: {
                            dataSource: window["DataSource_' + DataFieldName + '"] || [],
                            valueExpr: "ID",
                            displayExpr: "Name"
                        },
                        cellTemplate: function(cellElement, cellInfo){
                            const val = cellInfo.value;

                            if (val === undefined || val === null || val === "") {
                                $("<div>").addClass("dx-placeholder").text("").appendTo(cellElement);
                                return;
                            }

                            const ds = window["DataSource_' + DataFieldName + '"];
                            if (ds && Array.isArray(ds)) {
                                const f = ds.find(x => x.id == val || x.ID == val);
                                if (f) {
                                    $("<div>").text(f.Text || f.Name || "").appendTo(cellElement);
                                    return;
                                }
                            }

                            $("<div>").text(cellInfo.displayValue ?? val).appendTo(cellElement);
                },'

        ELSE
                        ISNULL('cellTemplate: function(cellElement, cellInfo) {
                            ' + REPLACE(REPLACE(REPLACE(loadUI_View, '%ColumnName%', DataFieldName),'"#%UID%"','cellElement'),'%DataSourceSP%',DataSourceSP) + N'

               const instance = Instance' + REPLACE(DataFieldName, '''', '''''') + N'%UID%;
         if (instance && cellInfo.value !== undefined && cellInfo.value !== null) {
                     instance.option("value", cellInfo.value);
                            }
                     },'
                        ,
               CASE
                        WHEN ControlType IN ('hpaControlDate','hpaControlTime','hpaControlDateTime') THEN
                    N'cellTemplate: function(cellElement, cellInfo){
                const val = cellInfo.value;

    if (!val) {
                                $("<div>").addClass("dx-placeholder").text("").appendTo(cellElement);
                                return;
                            }

   const d = new Date(val);
                            let text = "";

                            ' +
                       CASE
                         WHEN ControlType = 'hpaControlDate' THEN


                                    N'
                                    text = DevExpress.localization.formatDate(d, "dd/MM/yyyy");
                                    '
                                WHEN ControlType = 'hpaControlTime' THEN
  N'
           text = DevExpress.localization.formatDate(d, "HH:mm");
               '
           WHEN ControlType = 'hpaControlDateTime' THEN
                N'
                                    text = DevExpress.localization.formatDate(d, "dd/MM/yyyy HH:mm");
                                    '
                            END
                            + N'

                            $("<div>").text(text).appendTo(cellElement);
                        },'
                        ELSE
                            N''  -- control khác xử lý chỗ khác
                        END
                        )
                END
                +
                CASE
                WHEN HasEditMode = 1

                THEN
                ISNULL(
                        N'
                        allowEditing: true,
                        editCellTemplate: function(cellElement, cellInfo) {
                            // Cập nhật record context ID cho row hiện tại
                            let rowID = null;
                            if (cellInfo.key !== undefined && cellInfo.key !== null) {
                                rowID = cellInfo.key;
                            } else if (cellInfo.data && cellInfo.data["%ColumnIDName%"] !== undefined) {
                                rowID = cellInfo.data["%ColumnIDName%"];
                            }

                            if (rowID !== null) {
                                currentRecordID_%ColumnIDName% = rowID;
                            }

                            if ("%ColumnIDName2%" && "%ColumnIDName2%".trim() !== "" && cellInfo.data && cellInfo.data["%ColumnIDName2%"] !== undefined) {
                                currentRecordID_%ColumnIDName2% = cellInfo.data["%ColumnIDName2%"];
                            }

                        ' + REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(loadUI_Edit, '%ColumnName%', DataFieldName), '"#%UID%"', 'cellElement'), '%tableId%', CHECKSUM(tableId)), '%ColumnIDName%', ColumnIDName), '%ColumnIDName2%', ColumnIDName2) + N'
                            // Set initial value
                            if (cellInfo.value !== undefined && cellInfo.value !== null && Instance' + REPLACE(DataFieldName, '''', '''''') + N'%UID%) {
                                Instance' + REPLACE(DataFieldName, '''', '''''') + N'%UID%.option("value", cellInfo.value);
}

                        },'
   ,
N'
                            allowEditing: true,
editCellTemplate: function(cellElement, cellInfo) {
                                // Tạo một TextBox đơn giản để edit
                       const $input = $("<input>")
           .addClass("dx-texteditor-input")
                       .val(cellInfo.value || "")
                                    .appendTo(cellElement);

                                // Khởi tạo dxTextBox
                                const textBox = cellElement.dxTextBox({
                                    value: cellInfo.value,
                                    onValueChanged: function(e) {
                                        // Cập nhật giá trị vào grid
                                    cellInfo.setValue(e.value);
    }
        }).dxTextBox("instance");

                      // Focus vào input
      setTimeout(function() {
              $input.focus();
      }, 100);
                            },
          '
                    )

                ELSE N'
                    allowEditing: false,
 '
                END
                +'
            },
                '
            FROM #GridColumnsGrouped
            ORDER BY ColumnOrderID;
        END  -- END của ELSE (grid thường)

            -- Bỏ dấu phẩy cuối cùng
     IF LEN(@gridColumns) > 0
                SET @gridColumns = LEFT(@gridColumns, LEN(@gridColumns) - 1);

      -- UPDATE GRID CONTAINER CHO GRID HIỆN TẠI
            UPDATE t1
            SET
        loadUI = REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(REPLACE(
                    N'
                        window.Instance%ColumnName%%UID% = null;
                        { // Scope block to prevent style re-declaration conflicts
                             // Thêm responsive styles cho grid header
                        const style%ColumnName% = document.createElement("style");
                        style%ColumnName%.textContent = `
                            /* =============== RESPONSIVE POPUP STYLES =============== */
                            #%ColumnName% .dx-datagrid-search-panel .dx-placeholder {
                                display: none !important;
                             }
                             #%ColumnName% .dx-item-content.dx-toolbar-item-content {
                                 margin-right: 5px !important;
                             }

                            /* =============== FIX TEXTBOX TRONG GRID =============== */
                            #%ColumnName% .dx-datagrid .dx-texteditor {
                                width: 100% !important;
                                min-width: 0 !important;
                            }

   #%ColumnName% .dx-datagrid .dx-texteditor-input {
                                width: 100% !important;
                                min-width: 0 !important;
                                box-sizing: border-box !important;
                            }

                            #%ColumnName% .dx-datagrid-rowsview .dx-row > td > div {
                                white-space: nowrap;
                                overflow: hidden;
                                text-overflow: ellipsis;
                                word-break: break-word !important;
                                line-height: 1.4 !important;
                            }

                            #%ColumnName% .dx-popup.hpa-responsive {
                                max-width: 95vw !important;
                                max-height: 95vh !important;
                                width: 95vw !important;
                                left: 0 !important;
                                top: 0 !important;
                            }

                            #%ColumnName% .dx-popup.hpa-responsive .dx-popup-content {
                                height: calc(95vh - 120px) !important;
                                max-height: calc(95vh - 120px) !important;
                                overflow-y: auto !important;
            padding: 8px !important;
                                display: flex !important;
      flex-direction: column !important;
                            }

                 #%ColumnName% .dx-popup.hpa-responsive .dx-popup-content-scrollable {
                                flex: 1 !important;
 min-height: 0 !important;
   overflow: auto !important;
                            }

                            #%ColumnName% .dx-popup-content.dx-popup-content-scrollable {
                  height: auto !important;
                            }

                            #%ColumnName% .dx-popup.hpa-responsive .dx-toolbar-items {
           padding: 4px 0 !important;
                         flex-wrap: wrap;
                            }

                #%ColumnName% .dx-popup.hpa-responsive .dx-toolbar-item {
   margin: 2px 2px !important;
                            }

                            /* =============== GRID HEADER STYLES =============== */
             #%ColumnName% .dx-datagrid {
                                font-size: 14px;
                                table-layout: fixed !important;
                            }

                            /* FIX COLUMN WIDTH ALIGNMENT */
                            #%ColumnName% .dx-datagrid-table {
                                table-layout: fixed !important;
 width: 100% !important;
                            }

                            #%ColumnName% .dx-datagrid-headers .dx-datagrid-table {
                                table-layout: fixed !important;
           }

                            #%ColumnName% .dx-datagrid-rowsview .dx-datagrid-table {
                                table-layout: fixed !important;
                      }

              /* Ensure header and content cells have same width calculation */
                            #%ColumnName% .dx-datagrid .dx-header-row > td,
                            #%ColumnName% .dx-datagrid .dx-data-row > td {
                                box-sizing: border-box !important;
                                overflow: hidden !important;
                            }

                            #%ColumnName% .dx-datagrid-headers {
                                white-space: normal;
                                word-break: break-word;
                            }

                            #%ColumnName% .dx-datagrid-header-panel {
                                padding: 8px;
                            }

                            #%ColumnName% .dx-datagrid .dx-header-row {
     height: auto;
     min-height: 44px;
     }

                            #%ColumnName% .dx-datagrid .dx-row > td {
                                padding: 8px !important;
                                vertical-align: middle !important;
                            }

                            #%ColumnName% .dx-datagrid .dx-col-fixed {
                                z-index: 800 !important;
                            }

                            /* FORCE COLUMN WIDTH CONSISTENCY */
                            #%ColumnName% .dx-datagrid .dx-header-row > td,
                            #%ColumnName% .dx-datagrid .dx-data-row > td {
                                min-width: 0 !important;
                                width: auto !important;
                                max-width: none !important;
                            }

                            /* Prevent column width calculation conflicts */
                            #%ColumnName% .dx-datagrid-headers .dx-header-row td,
                            #%ColumnName% .dx-datagrid-rowsview .dx-data-row td {
                                position: relative !important;
                            }

                            /* Group row - sát mép */
                            #%ColumnName% .dx-datagrid .dx-group-row {

                             padding: 0 !important;
                          }

                            #%ColumnName% .dx-datagrid .dx-group-row > td {
                                padding: 8px !important;
                            }

                            #%ColumnName% .dx-datagrid .dx-group-row .dx-group-text {
                                padding: 0 !important;
                                margin: 0 !important;
                            }

            /* Mobile responsive */
  @media (max-width: 1024px) {
                                #%ColumnName% .dx-popup.hpa-responsive {
  max-width: 90vw !important;
  max-height: 90vh !important;
                                    width: 90vw !important;
                                    left: 5vw !important;
                                }
                                #%ColumnName% .dx-overlay-content.dx-popup-normal.dx-popup-draggable.dx-resizable {
                                    width: 90vw !important;
     max-width: 90vw !important;
   }
                                #%ColumnName% .dx-popup.hpa-responsive .dx-popup-content {
                                    max-height: calc(95vh - 120px) !important;
 }

                                /* Fix grid width alignment on tablet */
                                #%ColumnName% .dx-datagrid-table {
            min-width: 100% !important;
                                }
                            }

                            @media (max-width: 768px) {
               #%ColumnName% .dx-datagrid {
                                    font-size: 12px;
                                }

               /* Maintain fixed table layout on mobile */
          #%ColumnName% .dx-datagrid-table {
                     table-layout: fixed !important;
            min-width: 100% !important;
                       }

                                #%ColumnName% .dx-datagrid-headers {
         padding: 4px !important;
                               }

          #%ColumnName% .dx-datagrid .dx-header-row {
                                    height: auto;
                         min-height: 36px;
                                    padding: 0 !important;
                   }

                                #%ColumnName% .dx-datagrid-text-content {
                                    padding: 4px 2px !important;
                                    font-size: 11px !important;
     line-height: 1.3 !important;
       overflow: hidden !important;
                         white-space: nowrap !important;
                                    text-overflow: ellipsis !important;
                                    word-break: break-word !important;
                                }

                                #%ColumnName% .dx-datagrid-text-content.dx-header-filter {
                                    padding: 2px 1px !important;
                                }

                                #%ColumnName% .dx-checkbox {
                                    width: 24px !important;
                             height: 24px !important;
                  }

                                #%ColumnName% .dx-datagrid-rowsview {
                                    padding: 0 !important;
                                }

                                #%ColumnName% .dx-datagrid .dx-row {
                                    height: auto;
                                    min-height: 36px !important;
                                    padding: 0 !important;
                                }

                                #%ColumnName% .dx-datagrid .dx-data-row > td > div {
                                    padding: 4px 8px !important;

   white-space: nowrap !important;
                   text-overflow: ellipsis !important;
                                    word-break: break-word !important;
                                    vertical-align: middle !important;
                                    overflow: hidden !important;
                                    box-sizing: border-box !important;
                                }

                                #%ColumnName% .dx-datagrid .dx-group-row > td {
                                    padding: 4px 2px !important;
               }

       #%ColumnName% .dx-pager {
                                    padding: 4px 0 !important;
                                }

                                #%ColumnName% .dx-pager-page,
                        #%ColumnName% .dx-pager-navigation {
        padding: 2px 4px !important;
                                    font-size: 11px !important;
                                }

                                #%ColumnName% .dx-searchbox {
                                    width: 100% !important;
                                    max-width: none !important;
                     }

                       #%ColumnName% .dx-searchbox .dx-texteditor-input {
  padding: 4px !important;
                                    font-size: 12px !important;
                        height: 32px !important;
                              }

      #%ColumnName% .dx-popup.hpa-responsive {
                                    max-width: 95vw !important;
max-height: 85vh !important;
                                    width: 95vw !important;
                                    left: 2.5vw !important;
                                    top: 5vh !important;
                                }
                                #%ColumnName% .dx-overlay-content.dx-popup-normal.dx-popup-draggable.dx-resizable {
              width: 95vw !important;
                     max-width: 95vw !important;
        height: auto !important;
                                    max-height: 85vh !important;
   }
            #%ColumnName% .dx-popup.hpa-responsive .dx-overlay-wrapper {
                        position: fixed !important;
                                }
       #%ColumnName% .dx-popup.hpa-responsive .dx-popup-content {
             height: calc(95vh - 120px) !important;
                                    max-height: calc(95vh - 120px) !important;
                            font-size: 13px !important;
                                    padding: 6px !important;
               display: flex !important;
    flex-direction: column !important;
                                }

                                #%ColumnName% .dx-popup.hpa-responsive .dx-popup-content-scrollable {
                                    flex: 1 !important;
                                    min-height: 0 !important;
                                    overflow: auto !important;
                                }

                                #%ColumnName% .dx-popup-content.dx-popup-content-scrollable {
                                    height: auto !important;
                                }

                     /* Toolbar buttons */
                                #%ColumnName% .dx-popup.hpa-responsive .dx-toolbar-item .dx-button {
                                    padding: 6px 12px !important;
                                    font-size: 12px !important;
                                    min-height: 36px !important;
                                width: auto !important;
                                }
                                #%ColumnName% .dx-popup.hpa-responsive .dx-toolbar-item .dx-button .dx-button-text {
                        font-size: 12px !important;
                    }
                                #%ColumnName% .dx-popup.hpa-responsive .dx-button {
                                    padding: 6px 12px !important;
                                    font-size: 12px !important;
                                    min-height: 36px !important;
                                    width: auto !important;
                                }
                                #%ColumnName% .dx-popup.hpa-responsive .dx-button .dx-button-text {
                                    font-size: 12px !important;
     }
     #%ColumnName% .dx-popup.hpa-responsive .dx-datagrid {
                       font-size: 11px !important;
                                }
                                #%ColumnName% .dx-popup.hpa-responsive .dx-datagrid .dx-data-row td {
                                    padding: 4px 2px !important;
                 }
                            }

                            @media (max-width: 480px) {
             #%ColumnName% .dx-datagrid {
                                    font-size: 12px;
                                }

                                #%ColumnName% .dx-datagrid-headers {
        padding: 2px !important;
   }

                                #%ColumnName% .dx-datagrid .dx-header-row {
                              min-height: 32px;
                                }

                                #%ColumnName% .dx-datagrid-text-content {
                         padding: 2px 1px !important;
                                    font-size: 12px !important;
    }

                                #%ColumnName% .dx-checkbox {
width: 20px !important;
                                    height: 20px !important;

                                }


                                #%ColumnName% .dx-datagrid .dx-row {
          min-height: 32px;
                     }

                                #%ColumnName% .dx-datagrid .dx-data-row > td > div {
                     padding: 8px !important;
                                    font-size: 12px !important;
                                }

                  #%ColumnName% .dx-pager-page,
                                #%ColumnName% .dx-pager-navigation {
            padding: 1px 2px !important;
                                    font-size: 12px !important;
         }

                              #%ColumnName% .dx-popup.hpa-responsive {
                      max-width: 98vw !important;
               max-height: 80vh !important;
                      width: 98vw !important;
                left: 1vw !important;
  top: 10vh !important;
                                }
                                #%ColumnName% .dx-overlay-content.dx-popup-normal.dx-popup-draggable.dx-resizable {
                                    width: 98vw !important;
                                    max-width: 98vw !important;
                                    height: auto !important;
                                    max-height: 80vh !important;
                                }
                                #%ColumnName% .dx-popup.hpa-responsive .dx-overlay-wrapper {

                                    position: fixed !important;
                    }
                                #%ColumnName% .dx-popup.hpa-responsive .dx-popup-content {
                                    height: calc(95vh - 120px) !important;
                                    max-height: calc(95vh - 120px) !important;
                                    font-size: 12px !important;
                                    padding: 4px !important;
                                    display: flex !important;
                                 flex-direction: column !important;
 }

                                #%ColumnName% .dx-popup.hpa-responsive .dx-popup-content-scrollable {
                                    flex: 1 !important;
                                    min-height: 0 !important;
                                    overflow: auto !important;
                                }

                                #%ColumnName% .dx-popup-content.dx-popup-content-scrollable {
                                    height: auto !important;
                                }
                                /* Toolbar buttons */
                                #%ColumnName% .dx-popup.hpa-responsive .dx-toolbar-item .dx-button {
      padding: 4px 8px !important;
          font-size: 11px !important;
                  min-height: 32px !important;
                                    width: auto !important;
                                }
                                #%ColumnName% .dx-popup.hpa-responsive .dx-toolbar-item .dx-button .dx-button-text {
                                    font-size: 11px !important;
                                }
   #%ColumnName% .dx-popup.hpa-responsive .dx-button {
                      padding: 4px 8px !important;
                                    font-size: 11px !important;
                                    min-height: 32px !important;
                                    width: auto !important;
                                }
#%ColumnName% .dx-popup.hpa-responsive .dx-button .dx-button-text {
                                    font-size: 11px !important;
                                }
                                #%ColumnName% .dx-popup.hpa-responsive .dx-datagrid {
                                    font-size: 10px !important;
                                }

                                #%ColumnName% .dx-popup.hpa-responsive .dx-datagrid .dx-data-row td {
                        padding: 2px 1px !important;
                 font-size: 10px !important;
                                }
                                #%ColumnName% .dx-popup.hpa-responsive .dx-datagrid .dx-header-row {
                       min-height: 28px !important;
    }
    #%ColumnName% .dx-popup.hpa-responsive .dx-checkbox {
                                   width: 18px !important;
                height: 18px !important;
       }
      }
                        `;
                        document.head.appendChild(style%ColumnName%);
                        }

                      // Helper normalize function: bỏ dấu - dùng chung cho search/grid
   window.normalizeVietnameseText = window.normalizeVietnameseText || function(value) {
if (value === undefined || value === null) return "";
                            let text = String(value);
  if (typeof RemoveToneMarks_Js === "function") {
                                text = RemoveToneMarks_Js(text);
    } else if (text.normalize) {
                                text = text.normalize("NFD").replace(/[\u0300-\u036f]/g, "");
                            }
                            return text.replace(/đ/g, "d").replace(/Đ/g, "D").toLowerCase();
                        };

 // ===== Column chooser persistence helpers (shared) =====
                        let gridName = "%ColumnName%";
                        window.hpaColumnChooser = window.hpaColumnChooser || { saveTimers: {} };
                        let chooser = window.hpaColumnChooser;

                        if (!chooser.normalize) {
                            chooser.normalize = function(res) {
                                if (typeof res === "string" && res.trim() !== "") {
       return res.includes("{") ? JSON.parse(res) : JSON.parse(EncryptionStringDecryption(res));
               }
                                return res;
                            };
                        }

                        if (!chooser.load) {
                            chooser.load = function(gridInstance, gridNameParam) {
                                AjaxHPAParadise({
                                    data: {
                                        name: "sp_GridColumnChooser_Load",
                                        param: [
                                            "LoginID", window.UserID,
                                            "GridName", gridNameParam
          ]
        },
                                    success: function(res) {
                                        const json = chooser.normalize(res);
           const rows = (json?.data && json.data[0]) || [];
                                        const settingsJson = rows[0]?.SettingsJson;
                                        if (!settingsJson) return;
                                        let arr = [];
                                        try { arr = JSON.parse(settingsJson) || []; } catch(e) { arr = []; }
                                        arr.forEach(r => {
           if (!r.ColumnName) return;
                                            const opts = {};
     if (r.IsVisible !== undefined && r.IsVisible !== null) opts.visible = r.IsVisible === 1;
                                            if (r.OrderIndex !== undefined && r.OrderIndex !== null) opts.visibleIndex = r.OrderIndex;
                                            if (r.ColumnWidth !== undefined && r.ColumnWidth !== null) opts.width = r.ColumnWidth;
                                            gridInstance.columnOption(r.ColumnName, opts);
  });
                                    }
                                });
                            };
                        }

                        if (!chooser.save) {
                            chooser.save = function(gridInstance, gridNameParam) {
           const cols = (gridInstance.getColumns() || [])
                                    .map(c => {
               const name = c.dataField || c.name;
                                   if (!name) return null;
            return {
ColumnName: name,
        IsVisible: c.visible !== false ? 1 : 0,
                 OrderIndex: c.visibleIndex,
  ColumnWidth: c.width ? parseInt(c.width) : null
   };
    })
           .filter(Boolean);

                       AjaxHPAParadise({
       data: {
name: "sp_GridColumnChooser_Save",
     param: [
              "LoginID", window.UserID,
               "GridName", gridNameParam,
                      "Columns", JSON.stringify(cols)
          ]
                             },
                                    success: function(res) {
                                        if (typeof res === "string" && res.trim() !== "") {
                         res = res.includes("{") ? res : EncryptionStringDecryption(res);
                                        }
                                    }
                                });
                            };
                        }

         // =============== GRID CONFIG DYNAMIC BASED ON DATA SIZE ===============
              // Hàm tính remoteOperations dựa trên số lượng dòng
                window.getGridConfig_%ColumnName% = function(dataArray) {
                            const dataSize = Array.isArray(dataArray) ? dataArray.length : 0;
                            const isLargeDataset = dataSize > 1000;

                            return {
                                remoteOperations: isLargeDataset,
                                pageSize: 50,
                                allowedPageSizes: [5, 10, 50, 100]
                            };
                        };

                        Instance%ColumnName%%UID% = $("#%ColumnName%").dxDataGrid({
                            dataSource: [],
                   keyExpr: "%PKColumnName%",
        height: "100%",
                            width: "100%",
    showBorders: true,
                            showRowLines: true,
          rowAlternationEnabled: false,
                            hoverStateEnabled: false,
            columnAutoWidth: true,
allowColumnReordering: true,
                            allowColumnResizing: true,
                            columnResizingMode: "widget",
                            columnMinWidth: 80,
                            wordWrapEnabled: true,

                            scrolling: {
                                mode: "standard",
                                showScrollbar: "onHover"
                            },

                            paging: {
                               enabled: true,
   pageSize: 50
                            },

                            pager: {
  visible: true,
                                allowedPageSizes: [5, 10, 50, 100],
                          showPageSizeSelector: true,
              showInfo: true,
                                showNavigationButtons: true
       },

                            selection: {
   mode: "%SelectionMode%",
                   showCheckBoxesMode: "%ShowCheckBoxesMode%",
                                allowSelectAll: %AllowSelectAll%
       },

      searchPanel: {
   visible: true,
 width: 260,
highlightSearchResults: false,
                             highlightCaseSensitive: false,
                                placeholder: "Tìm kiếm theo nội dung"
                            },


                            headerFilter: { visible: true },

             columnChooser: {
               enabled: true,
               mode: "select",
                            title: "Chọn cột hiển thị",
           allowSearch: true
  },

                            stateStoring: {
                                enabled: false,
     type: "localStorage",
                                storageKey: "gridState_%ColumnName%"
                            },

                            grouping: {
              autoExpandAll: false,
         contextMenuEnabled: false,
            allowCollapsing: false
                    },

                     groupPanel: { visible: false },

                    columnFixing: { enabled: false },

                    customizeColumns: function(columns) {

                                const normalizeText = window.normalizeVietnameseText || function(val) {
                           if (val === undefined || val === null) return "";

                                    return String(val).toLowerCase();
     };

                           columns.forEach(function(column) {
                                    if (column._hpaSearchNormalized) return;
    column._hpaSearchNormalized = true;

                                    const originalCalculate = column.calculateFilterExpression;
                                    const dataFieldPath = column.dataField || column.name || "";
                                    const getValue = column.calculateCellValue
                                        ? column.calculateCellValue.bind(column)
                                        : function(dataObj) {
                                            if (!dataObj || !dataFieldPath) return null;
                                            if (dataFieldPath.indexOf(".") === -1) {
                                                return dataObj[dataFieldPath];
                                            }
                 return dataFieldPath.split(".").reduce(function(acc, key) {
                                return acc && acc[key] !== undefined ? acc[key] : null;
                        }, dataObj);
                                        };

         column.calculateFilterExpression = function(filterValue, selectedFilterOperation, target) {
                                   if (target === "search") {
                       const normalizedFilter = normalizeText(filterValue);
                                            if (!normalizedFilter) {
                                                if (originalCalculate) {
                                                    return originalCalculate.call(this, filterValue, selectedFilterOperation, target);
                                                }
                                                if (this.defaultCalculateFilterExpression) {
                                                    return this.defaultCalculateFilterExpression(filterValue, selectedFilterOperation, target);
        }
                                                return null;
                                            }

       return function(dataItem) {
    const rawValue = getValue ? getValue(dataItem) : null;
                                           const normalizedValue = normalizeText(rawValue);
     return normalizedValue.indexOf(normalizedFilter) > -1;
          };
                         }

                                        if (originalCalculate) {
                               return originalCalculate.call(this, filterValue, selectedFilterOperation, target);
    }

       if (this.defaultCalculateFilterExpression) {
                                            return this.defaultCalculateFilterExpression(filterValue, selectedFilterOperation, target);
                                        }

          return null;
                                    };
                                });
                            },

                            editing: {
                     mode: "cell",
                                allowUpdating: false
                            },
                        rowDragging: {
                                allowReordering: false,
                                showDragIcons: false
   }
         ,
                            onToolbarPreparing: function(e) {
                                // Nút thêm (+) — _showtoolbarAdd_<UID>
                                if (typeof _showtoolbarAdd_%UID% !== "undefined" && _showtoolbarAdd_%UID% == true) {
                                    let index = e.toolbarOptions.items.findIndex(i => i.name === "columnChooserButton");
                                    if (index === -1) index = e.toolbarOptions.items.length;

                                    e.toolbarOptions.items.splice(index, 0, {
                                        location: "after",
                                        widget: "dxButton",
                                        options: {
                                            icon: "add",
                                            text: "",
                                            stylingMode: "text",
                                            elementAttr: { style: "color: var(--bs-body-color, #000);" },
                                            onClick: function() {
                                                    add%PKColumnName%();
                                            }
                                        }
                                    });
                                }
                                // Nút reload — _showtoolbarGrid_<UID>
                                if (typeof _showtoolbarGrid_%UID% !== "undefined" && _showtoolbarGrid_%UID% == true) {
                                    let index = e.toolbarOptions.items.findIndex(i => i.name === "columnChooserButton");
                                    if (index === -1) index = e.toolbarOptions.items.length;

                                    e.toolbarOptions.items.splice(index, 0, {
                                        location: "after",
                                        widget: "dxButton",
                                        options: {
                                            icon: "refresh",
                                            stylingMode: "text",
                                            elementAttr: { style: "color: var(--bs-body-color, #000);" },
                                            onClick: function() {
                                                    ReloadData();
                                            }
                                        }
                                    });
                                }
                            },
                            noDataText: "Không có dữ liệu",
                            columns: [
                                ' + @gridColumns + N'
                            ],
              onCellClick(e) {
                                if (%IsOpenDetailRowGrid% !== 1) return;

              // Nếu có multi select:
                                // - Click vào detail column (_detailAction) thì mở detail
   // - Click vào checkbox column thì chỉ select
                               // - Click vào columns khác thì không làm gì
                                if (%IsMultiSelectRowGrid% === 1) {
                                    if (e.column.dataField === "_detailAction") {
        // Click vào detail button - mở detail
          const rowDataObject = e.data;
                                        const recordID = e.key ?? e.data?.["%PKColumnName%"];
                                        if (!recordID) return;
  window.currentClicked_%ColumnName% = recordID;
                                        window.currentRecordID_%PKColumnName% = recordID;
                                  openDetail%PKColumnName%?.(rowDataObject);
        }
       return; // Không xử lý các column khác khi có multi select
                               }

                                const rowDataObject = e.data;

                                const recordID = e.key ?? e.data?.["%PKColumnName%"];
                                if (!recordID) return;
                                window.currentClicked_%ColumnName% = recordID;
                    window.currentRecordID_%PKColumnName% = recordID;
openDetail%PKColumnName%?.(rowDataObject);
                    },
                            onRowPrepared(e) {

                            }
                           ,
                            onOptionChanged(e) {
                                // Persist column chooser changes (visibility/order/width)
                          if (e.fullName && e.fullName.startsWith("columns[")) {
     const timers = chooser.saveTimers;
                                    if (timers[gridName]) {
                                        clearTimeout(timers[gridName]);
                                    }
                          timers[gridName] = setTimeout(function(){
                                        chooser.save(Instance%ColumnName%%UID%, gridName);
                                    }, 400);
  }
                            }

                        }).dxDataGrid("instance");

                        // Load saved column chooser settings after grid init
                        chooser.load(Instance%ColumnName%%UID%, gridName);

                        // Shared grid data source registry so detail forms can trigger refreshes
                        window.hpaSharedGridDataSources = window.hpaSharedGridDataSources || {};

                        if (!window.reloadSharedGridDataSource) {
                            window.reloadSharedGridDataSource = function(name, params) {
                                const registry = window.hpaSharedGridDataSources || {};
                         const entry = registry[name];
                                if (!entry || typeof entry.reload !== "function") {
                                    console.warn("[SharedGrid] Grid", name, "is not registered");
                                    return Promise.resolve([]);
                          }
 return entry.reload(params);
                            };
                        }

 if (!window.getSharedGridDataSource) {
                      window.getSharedGridDataSource = function(name) {
                                const registry = window.hpaSharedGridDataSources || {};
                                return registry[name];
                            };
                        }

       if (!window.updateSharedGridRow) {
                       window.updateSharedGridRow = function(name, rowData, options) {
                              const registry = window.hpaSharedGridDataSources || {};
                         const entry = registry[name];
                                if (!entry || typeof entry.pushRow !== "function") {
                               console.warn("[SharedGrid] Grid", name, "cannot accept row updates");
                                    return Promise.resolve(false);
                                }
                           return entry.pushRow(rowData, options);
         };
                        }

                        if (!window.syncSharedGridData) {
                     window.syncSharedGridData = function(name) {
                                const registry = window.hpaSharedGridDataSources || {};
                                const entry = registry[name];
         if (!entry || typeof entry.syncFromGrid !== "function") {
                               console.warn("[SharedGrid] Grid", name, "cannot sync");
                                    return [];
                     }
    return entry.syncFromGrid();
                            };
         }

                        if (!window.removeSharedGridRow) {
        window.removeSharedGridRow = function(name, options) {
                         const registry = window.hpaSharedGridDataSources || {};
const entry = registry[name];
                                if (!entry || typeof entry.removeRow !== "function") {
                                    console.warn("[SharedGrid] Grid", name, "cannot remove rows");
                  return Promise.resolve(false);
                                }
                                return entry.removeRow(options);
                            };
                        }

                        (function setupSharedGridSource() {
                            const sharedKey = gridName;
                            const primaryKeyField = "%PKColumnName%";

                            const loginValue = typeof window.UserID !== "undefined"
                    ? window.UserID
                                : (typeof LoginID !== "undefined" ? LoginID : null);
                            const languageValue = typeof window.LanguageID !== "undefined"
                                ? window.LanguageID
                                : (typeof LanguageID !== "undefined" ? LanguageID : null);

                            const snapshotGridData = function(instance) {
if (!instance) return [];
                                try {
                                    // Ưu tiên đọc raw dataSource trước - luôn có FULL data
                                    // kể cả khi toolbar search/filter đang active
                                    if (typeof instance.option === "function") {
  const rawData = instance.option("dataSource");
                                        if (Array.isArray(rawData) && rawData.length > 0) {
                                            return rawData.map(function(item) {
                                                return item && typeof item === "object" ? Object.assign({}, item) : item;
                                            });
                                        }
                                    }

                           // Fallback: ds.items() - CHÚ Ý: chỉ trả về filtered rows
                                    if (typeof instance.getDataSource === "function") {
       const ds = instance.getDataSource();
                                        if (ds && typeof ds.items === "function") {
                                       const dsItems = ds.items();
                                            if (Array.isArray(dsItems) && dsItems.length > 0) {
                    return dsItems.map(function(item) {
                                                    return item && typeof item === "object" ? Object.assign({}, item) : item;
                });
      }
                                        }
                                    }
              } catch (snapshotErr) {
       console.warn("[SharedGrid] Unable to snapshot grid data", snapshotErr);
}
                                return [];
                            };

                            let sharedEntry = window.hpaSharedGridDataSources[sharedKey];
                            if (!sharedEntry) {
     sharedEntry = {
data: [],
                                    subscribers: [],
loading: false
  };
                      }

sharedEntry.primaryKey = sharedEntry.primaryKey || primaryKeyField;
                            sharedEntry.data = Array.isArray(sharedEntry.data) ? sharedEntry.data : [];
                            sharedEntry.subscribers = Array.isArray(sharedEntry.subscribers) ? sharedEntry.subscribers : [];

                        sharedEntry.loading = !!sharedEntry.loading;

 if (typeof sharedEntry.normalizeParams !== "function") {
   sharedEntry.normalizeParams = function(customParams) {
                                    const base = [];
      if (loginValue !== null && loginValue !== undefined) {
                                        base.push("LoginID", loginValue);
                                    }
                                    if (languageValue !== null && languageValue !== undefined) {
                                        base.push("LanguageID", languageValue);
                                    }

                       if (Array.isArray(customParams) && customParams.length > 0) {
                                        return base.concat(customParams);
                                    }

                                    if (customParams && typeof customParams === "object") {
             const extras = [];
                                        Object.keys(customParams).forEach(function(key) {
              extras.push(key, customParams[key]);
                                        });
                                        return base.concat(extras);
                                    }

       return base;
                                };
                            }

                            if (typeof sharedEntry.notify !== "function") {
                                sharedEntry.notify = function() {
                         this.subscribers.forEach(function(callback) {
                              try {
                                            callback(this.data);
                                        } catch (err) {
                                            console.error("[SharedGrid] subscriber error", err);
                                        }
                                    }, this);
                                };
                       }

                            if (typeof sharedEntry.subscribe !== "function") {
                                sharedEntry.subscribe = function(callback) {
                               if (typeof callback === "function") {
                                        this.subscribers.push(callback);
               }
                                    return () => {

                                        this.subscribers = this.subscribers.filter(function(fn) {
           return fn !== callback;
                                        });
        };
                                };
  }

                  if (typeof sharedEntry.pushRow !== "function") {
                  sharedEntry.pushRow = function(rowData, options) {
     const opts = options || {};
                                    const keyField = this.primaryKey;
                                    let keyValue = opts.key;
                                   if ((keyValue === undefined || keyValue === null) && rowData && rowData[keyField] !== undefined) {
                    keyValue = rowData[keyField];
 }

    if (keyValue === undefined || keyValue === null) {
                    console.warn("[SharedGrid] Missing key when applying row changes for", sharedKey);
                       return Promise.resolve(false);
         }

  if (typeof this.ensureLocalData === "function") {
                                        this.ensureLocalData();
              }

   const compare = opts.strict === true
        ? function(candidate) { return candidate === keyValue; }
   : function(candidate) {
                                            if (candidate === undefined || candidate === null) return candidate === keyValue;
                                if (keyValue === undefined || keyValue === null) return false;
                                            return String(candidate) === String(keyValue);
                                     };

                                const nextData = Array.isArray(this.data) ? this.data.slice() : [];
                                    let targetIndex = nextData.findIndex(function(item) {
                                        return item ? compare(item[keyField]) : false;
                     });

                                    const normalizedRow = Object.assign({}, targetIndex > -1 ? nextData[targetIndex] : {}, rowData);

                                    if (targetIndex === -1) {
                                        if (opts.ignoreMissing === true) {
                  return Promise.resolve(false);
                                        }
                                        if (opts.append === true) {
                        nextData.push(normalizedRow);
                                            targetIndex = nextData.length - 1;
                                        } else {
                                  nextData.unshift(normalizedRow);
                                            targetIndex = 0;
             }
                  } else {
                         nextData[targetIndex] = normalizedRow;
                                    }

        this.data = nextData;
   try {
                                         if (this.instance && typeof this.instance.option === "function") {
                            const ds = this.instance.getDataSource();
                            const store = ds && typeof ds.store === "function" ? ds.store() : null;

                            // FIX: Nếu là CustomStore/RemoteStore thì dùng push() để không làm hỏng Store gốc
                            if (store && typeof store.push === "function" && !Array.isArray(this.instance.option("dataSource"))) {
                                store.push([{ type: (targetIndex === -1 ? "insert" : "update"), key: keyValue, data: normalizedRow }]);
                            } else {
                                // Nếu là Array Grid bình thường thì mới ghi đè dataSource
                                this.instance.option("dataSource", nextData);
                            }
                            this.instance.refresh();
                        }
                                    } catch (applyErr) {
                                        console.warn("[SharedGrid] Unable to push row update", applyErr);
                             }
                                    this.notify();
                                    return Promise.resolve({ index: targetIndex, data: normalizedRow });
                        };
      }

                            if (typeof sharedEntry.removeRow !== "function") {
          sharedEntry.removeRow = function(options) {
                                    const opts = options || {};
          const keyField = this.primaryKey;
                                    const keyValue = opts.key;

                                if (keyValue === undefined || keyValue === null) {
                                        console.warn("[SharedGrid] Missing key when removing row for", sharedKey);
          return Promise.resolve(false);
                                    }

                                    if (typeof this.ensureLocalData === "function") {
         this.ensureLocalData();
                                    }

                           const filtered = (Array.isArray(this.data) ? this.data : []).filter(function(item) {
                     if (!item) return true;
   const candidate = item[keyField];
                    if (opts.strict === true) {
            return candidate !== keyValue;
             }
                                        if (candidate === undefined || candidate === null) {
                                            return keyValue !== candidate;
    }
                                        return String(candidate) !== String(keyValue);
                                    });


          if (filtered.length === (Array.isArray(this.data) ? this.data.length : 0)) {
                             return Promise.resolve(false);
       }

       this.data = filtered;
                                    try {
                                        if (this.instance && typeof this.instance.option === "function") {
                  this.instance.option("dataSource", filtered);
                                            this.instance.refresh();
                                        }
} catch (removeErr) {
                                        console.warn("[SharedGrid] Unable to remove row", removeErr);
                     }
                                    this.notify();
                                    return Promise.resolve(true);
                            };
                            }

                            sharedEntry.instance = Instance%ColumnName%%UID%;

                  if (typeof sharedEntry.ensureLocalData !== "function") {
                                sharedEntry.ensureLocalData = function() {
             if (Array.isArray(this.data) && this.data.length > 0) {
                                        return;
                   }
       const snapshot = snapshotGridData(this.instance);
                                    if (snapshot.length > 0) {
                                        this.data = snapshot;
      }
                                };
                    }

                            const currentSnapshot = snapshotGridData(sharedEntry.instance);
                            if (currentSnapshot.length > 0) {
                                sharedEntry.data = currentSnapshot;
                            }

                            sharedEntry.getData = function() {
                                return this.data;
                            };

                            // Gọi sau khi API reload data mới để sync lại cache
                            sharedEntry.syncFromGrid = function() {
                                const fresh = snapshotGridData(this.instance);
                                if (fresh.length > 0) {
                         this.data = fresh;
                                }
                                return this.data;
                            };

                            window.hpaSharedGridDataSources[sharedKey] = sharedEntry;
                        })();
                    ',
          '%COLUMNS%', @gridColumns),
          '%PKColumnName%', @PKColumnNameGrid),
                    '%Layout%', Layout),
             '%UID%', [UID]),
                    '%ColumnName%', ColumnName),
                    '%IsOpenDetailRowGrid%', ISNULL(IsOpenDetailRowGrid, 0)),
                    '%IsMultiSelectRowGrid%', ISNULL(IsMultiSelectRowGrid, 0)),
                    '%SelectionMode%', CASE WHEN ISNULL(IsMultiSelectRowGrid, 0) = 1 THEN 'multiple' ELSE 'single' END),
                    '%ShowCheckBoxesMode%', CASE WHEN ISNULL(IsMultiSelectRowGrid, 0) = 1 THEN 'always' ELSE 'none' END),
                    '%AllowSelectAll%', CASE WHEN ISNULL(IsMultiSelectRowGrid, 0) = 1 THEN 'true' ELSE 'false' END),
     '%AllowUpdating%', CASE WHEN @IsSimpleViewGrid = 1 THEN 'false' ELSE 'true' END),
                    '%AllowReordering%', CASE WHEN @IsSimpleViewGrid = 1 THEN 'false' ELSE 'true' END),
html = N'<div id="%ColumnName%" style="height: 100%;"></div>'
            FROM #temptable t1
      WHERE t1.Type IN ('hpaControlGrid', 'hpaControlGrid_Duc')
              AND t1.ColumnName = @GridColumnName;

           FETCH NEXT FROM @GridColumnsCursor INTO @GridColumnName;
      END;

        CLOSE @GridColumnsCursor;
     DEALLOCATE @GridColumnsCursor;
    END

    -- ============================================================================
    -- OPTIMIZE: Collect unique DataSourceSP và gọi API 1 lần
    -- ============================================================================
    DECLARE @UniqueDataSources TABLE (
        DataSourceSP VARCHAR(256),
        ColumnNames NVARCHAR(MAX)
    );

    -- Insert các DataSourceSP unique vào temp table
    INSERT INTO @UniqueDataSources (DataSourceSP, ColumnNames)
    SELECT
        DatasourceSP,
        STRING_AGG(ColumnName, ',') WITHIN GROUP (ORDER BY ColumnName)
    FROM #temptable
    WHERE DatasourceSP IS NOT NULL
      AND LTRIM(RTRIM(DatasourceSP)) <> ''
      AND ColumnName IS NOT NULL
    GROUP BY DatasourceSP;

    -- Xóa các dòng build control cho grid sau khi đã nối chuỗi xong
    DELETE FROM #temptable WHERE Layout = 'Grid_View' AND GridColumnName IS NOT NULL;

    -- ============================================================================
   -- THAY THẾ CÁC PLACEHOLDER
    -- ============================================================================
    DECLARE @ChecksumCache TABLE (TableEditor NVARCHAR(256), ChecksumVal VARCHAR(64));

    -- Lấy checksum của các bảng được sử dụng trong TableEditor
    INSERT INTO @ChecksumCache (TableEditor, ChecksumVal)
    SELECT DISTINCT t.TableEditor, CAST(CHECKSUM(o.name) AS VARCHAR(64))
    FROM #temptable t
    LEFT JOIN sys.objects o ON o.name = t.TableEditor AND o.type = 'U'
    WHERE t.TableEditor IS NOT NULL;

    DECLARE @ChecksumTableAddCache TABLE (TableAddNew NVARCHAR(256), ChecksumVal VARCHAR(64));

    INSERT INTO @ChecksumTableAddCache (TableAddNew, ChecksumVal)
    SELECT DISTINCT t.TableAddNew, CAST(CHECKSUM(o.name) AS VARCHAR(64))
    FROM #temptable t
    LEFT JOIN sys.objects o ON o.name = t.TableAddNew AND o.type = 'U'
    WHERE t.TableAddNew IS NOT NULL;
	
	UPDATE t
        SET loadUI = REPLACE(loadUI, '%tableId%', CAST(CHECKSUM(o.name) AS VARCHAR(64)))
        FROM #temptable t
        INNER JOIN sys.objects o ON o.name = t.TableEditor AND o.type = 'U'
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%tableId%', ISNULL(@object_Id, ''))
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%UID%', ISNULL([UID], ''))
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%TableName%', ISNULL(TableName, ''))
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%ColumnNameSync%', ISNULL(ColumnNameSync, ''))
        UPDATE #temptable SET loadUI = REPLACE(loadUI, '%ColumnName%', ISNULL(ColumnName, ''))
    update #temptable set loadUI = REPLACE(loadUI,'%TabIndex%',isnull(nullif(TabIndex,''),''))
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%DatasourceSP%', ISNULL(DatasourceSP, ''))
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%columnId%', ISNULL(columnId, ''))
 UPDATE #temptable SET loadUI = REPLACE(loadUI, '%ColumnIDName%', ISNULL(ColumnIDName, ''))

    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%ColumnIDName2%', ISNULL(ColumnIDName2, ''))
 UPDATE #temptable SET loadUI = REPLACE(loadUI, '%Layout%', ISNULL(Layout, ''))
    --UPDATE #temptable SET loadUI = REPLACE(loadUI, '%IsAlert%', ISNULL(IsAlert, 0))
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%TableAddNew%', ISNULL((SELECT TOP 1 ChecksumVal FROM @ChecksumTableAddCache WHERE TableAddNew = #temptable.TableAddNew), ''));
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%TableAddNewD%', ISNULL(TableAddNew, ''))
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%ColumnNameAddNew%', ISNULL(ColumnNameAddNew, ''))
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%ActionRichTextEditor%', ISNULL(ActionRichTextEditor, ''))
	UPDATE #temptable SET loadUI = REPLACE(loadUI, '%IsRequired%', ISNULL(IsRequired, ''))
	UPDATE #temptable SET loadUI = REPLACE(loadUI, '%GridColumnName%', ISNULL(GridColumnName, 0))

	UPDATE #temptable SET loadUI = REPLACE(loadUI, '%CustomValidate%', ISNULL(CustomValidate, 0))
	UPDATE #temptable SET loadUI = REPLACE(loadUI, '%KeyUpdateGrid%', ISNULL(KeyUpdateGrid, 0))
	UPDATE #temptable SET loadUI = REPLACE(loadUI, '%AutoSave%', ISNULL(AutoSave, 0))
	UPDATE #temptable SET loadUI = REPLACE(loadUI, '%DisplayName%', ISNULL(DisplayName, 0))
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%UseActionRichTextEditor%', ISNULL(UseActionRichTextEditor, ''));
    UPDATE #temptable SET loadUI = REPLACE(loadUI, '%ShowDataBeforeSearch%', CASE WHEN ISNULL(TableAddNew, '') <> '' THEN 'false' ELSE 'true' END);

    UPDATE #temptable SET loadData = REPLACE(loadData, '%UID%', ISNULL([UID], ''))
    UPDATE #temptable SET loadData = REPLACE(loadData, '%ColumnName%', ISNULL(ColumnName, ''))
    UPDATE #temptable SET loadData = REPLACE(loadData, '%DatasourceSP%', ISNULL(DatasourceSP, ''))
    UPDATE #temptable SET loadData = REPLACE(loadData, '%columnId%', ISNULL(columnId, ''))
    UPDATE #temptable SET loadData = REPLACE(loadData, '%ColumnIDName%', ISNULL(ColumnIDName, ''))
   UPDATE #temptable SET loadData = REPLACE(loadData, '%ColumnIDName2%', ISNULL(ColumnIDName2, ''))
    UPDATE #temptable SET loadData = REPLACE(loadData, '%Layout%', ISNULL(Layout, ''))

    UPDATE #temptable SET html = REPLACE(html, '%UID%', ISNULL([UID], ''))
    UPDATE #temptable SET html = REPLACE(html, '%Layout%', ISNULL(Layout, ''))
    UPDATE #temptable SET html = REPLACE(html, '%ColumnName%', ISNULL(ColumnName, ''))

    -- ============================================================================
    -- XUẤT KẾT QUẢ CUỐI CÙNG
    -- ============================================================================
    DECLARE @SPLoadData VARCHAR(100), @ColumnIDName VARCHAR(100), @UID VARCHAR(100), @ColumnName VARCHAR(100);
    DECLARE @ColumnIDNames TABLE (ColumnIDName VARCHAR(200));
    DECLARE @ColumnIDNames2 TABLE (ColumnIDName2 VARCHAR(200));

    -- Lấy thông tin cơ bản
    SELECT TOP 1 @SPLoadData = SPLoadData FROM #temptable WHERE TableName = @TableName
    SELECT TOP 1 @UID = [UID] FROM #temptable WHERE TableName = @TableName
    SELECT TOP 1 @ColumnName = [ColumnName] FROM #temptable WHERE TableName = @TableName
    SELECT TOP 1 @GridColumnName = [ColumnName] FROM #temptable WHERE TableName = @TableName AND Layout = 'Grid_View'

    -- Lấy PKColumnName từ ColumnIDName của row container grid
    DECLARE @PKColumnNameHtml VARCHAR(200) = 'ID';
    SELECT TOP 1 @PKColumnNameHtml = ISNULL(ColumnIDName, 'ID')
    FROM #temptable
    WHERE TableName = @TableName
      AND Layout = 'Grid_View'
      AND Type IN ('hpaControlGrid', 'hpaControlGrid_Duc');

    -- Lấy danh sách ColumnIDName
    INSERT INTO @ColumnIDNames(ColumnIDName)
    SELECT DISTINCT ColumnIDName
    FROM #temptable
    WHERE TableName = @TableName
      AND ColumnIDName IS NOT NULL;

    INSERT INTO @ColumnIDNames2(ColumnIDName2)
    SELECT DISTINCT ColumnIDName2
    FROM #temptable
    WHERE TableName = @TableName
      AND ColumnIDName2 IS NOT NULL;

    -- Build JavaScript variables cho currentRecordID
    DECLARE @jsCurrentRecordID NVARCHAR(MAX) = N'';
    DECLARE @jsCurrentRecordID2 NVARCHAR(MAX) = N'';

    -- Thay đổi cách build @jsCurrentRecordID
    SELECT @jsCurrentRecordID += ' window.currentRecordID_' + ColumnIDName + ' = null;'
    FROM @ColumnIDNames
    WHERE ColumnIDName IS NOT NULL;

SELECT @jsCurrentRecordID2 += ' window.currentRecordID_' + ColumnIDName2 + ' = null;'
    FROM @ColumnIDNames2
    WHERE ColumnIDName2 IS NOT NULL;

    DECLARE @jsHandleRecord NVARCHAR(MAX) = N'';
    DECLARE @jsHandleRecord2 NVARCHAR(MAX) = N'';

    SELECT @jsHandleRecord += ' if (obj) { window.currentRecordID_' + ColumnIDName + ' = (obj.' + ColumnIDName + ' !== undefined && obj.' + ColumnIDName + ' !== null) ? obj.' + ColumnIDName + ' : window.currentRecordID_' + ColumnIDName + '; }'
    FROM @ColumnIDNames;

SELECT @jsHandleRecord2 += ' if (obj) { window.currentRecordID_' + ColumnIDName2 + ' = (obj.' + ColumnIDName2 + ' !== undefined && obj.' + ColumnIDName2 + ' !== null) ? obj.' + ColumnIDName2 + ' : window.currentRecordID_' + ColumnIDName2 + '; }'
    FROM @ColumnIDNames2;

    -- Build JavaScript code để load tất cả unique DataSourceSP
    DECLARE @jsLoadAllDataSources NVARCHAR(MAX) = N'';

    SELECT @jsLoadAllDataSources += N'
       // Load DataSource: ' + DataSourceSP + N'
if ("' + DataSourceSP + N'" && "' + DataSourceSP + N'".trim() !== "") {
 loadDataSourceCommon("' + LEFT(ColumnNames, CHARINDEX(',', ColumnNames + ',') - 1) + N'", "' + DataSourceSP + N'", function(data) {
    // Data được shared qua callback
                });
            }
        '
    FROM @UniqueDataSources
    WHERE DataSourceSP IS NOT NULL;

    IF ISNULL(LTRIM(RTRIM(@jsLoadAllDataSources)), '') <> ''
    BEGIN
    SET  @jsLoadAllDataSources += N'
        function loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback) {
            if (!columnName || !dataSourceSP || dataSourceSP.trim() === "") {
                console.warn("[loadDataSourceCommon] Missing columnName or dataSourceSP");
return;
            }

            const dataSourceKey = "DataSource_" + columnName;
       // Sử dụng format: columnNameDataSourceLoaded để tương thích với code hiện tại
            const loadedKey = columnName + "DataSourceLoaded";

    // Kiểm tra nếu đã load rồi thì không load lại

            if (window[loadedKey] === true) {
if (typeof onSuccessCallback === "function") {
  onSuccessCallback(window[dataSourceKey] || []);
                }
                return;
     }

            // Kiểm tra nếu đang load thì đợi
            if (window[loadedKey] === "loading") {
                // Đợi một chút rồi thử lại
   setTimeout(function() {
                    loadDataSourceCommon(columnName, dataSourceSP, onSuccessCallback);
                }, 100);

                return;
            }


            // Đánh dấu đang load để tránh load trùng lặp
            window[loadedKey] = "loading";

            return new Promise((resolve, reject) => {
                AjaxHPAParadise({
                    data: {
                        name: dataSourceSP,
        param: ["LoginID", LoginID, "LanguageID", LanguageID]
            },
                    success: function (res) {
                        const json = typeof res === "string" ? JSON.parse(res) : res;

           window[dataSourceKey] = (json.data && json.data[0]) || [];
                        window[loadedKey] = true;

                        // Ưu tiên lấy từ json response (nếu API trả về explicit)
          // Sau đó mới fallback query dataSchema
                        let idField = json.valueExpr;
                let nameField = json.displayExpr;

                        if (!idField || !nameField) {
                            if (json.dataSchema && json.dataSchema[0]) {
                                const schema = json.dataSchema[0];
 if (!idField) idField = schema[0]?.name;
                                if (!nameField) nameField = schema[1]?.name;
        }
                        }

                        window["DataSourceIDField_" + columnName]   = idField || "ID";
                        window["DataSourceNameField_" + columnName] = nameField || "Name";

                        const data = window[dataSourceKey];

                        // callback trước
                        if (typeof onSuccessCallback === "function") {
                            onSuccessCallback(data, json);
                        }

                        // resolve sau
                        resolve(data);
                    },
                    error: function (err) {
                        console.error("[loadDataSourceCommon] Failed to load datasource for", columnName, ":", err);
      window[loadedKey] = false;

                        if (typeof onSuccessCallback === "function") {
          onSuccessCallback([]);
                        }

                        reject(err);
                    }
});
            });
     }
    ';
    END

    DECLARE @jsLayoutHandling NVARCHAR(MAX) = N'';
    IF @UseLayout = 1
    BEGIN
SET @jsLayoutHandling = N'
        // Xử lý cho grid layout - server-side paging qua CustomStore
 const gridInstance = Instance%GridColumnName%%UID%;
        gridInstance.beginUpdate();
    gridInstance.option("scrolling", { mode: "standard", showScrollbar: "onHover" });
        gridInstance.option("remoteOperations", { paging: true, filtering: true });
        gridInstance.option("paging.enabled", true);
        gridInstance.option("paging.pageSize", pageSize);
        gridInstance.option("pager.allowedPageSizes", [5, 10, 50, 100]);
        gridInstance.option("searchPanel.highlightSearchText", false);
        gridInstance.option("dataSource", dataStore_%GridColumnName%);
        gridInstance.option("onOptionChanged", function(e) {
             if (e.name === "searchPanel" && e.fullName === "searchPanel.text") {
                const raw = e.value || "";

                let t = String(raw);
                _currentKeyword = t.trim();
                _pageCache = {};
            }
    }
        });
        gridInstance.endUpdate();

';
    END

    -- ============================================================================
    -- BUILD HTML OUTPUT
    -- ============================================================================
    DECLARE @UID_Grid NVARCHAR(100);
    SELECT TOP 1 @UID_Grid = CAST(UID AS NVARCHAR(100))
FROM #temptable t1
WHERE t1.Type IN ('hpaControlGrid_Duc');

    DECLARE @nsqlHtml NVARCHAR(MAX) = N'
    <div id="%TableName%">
        %paradisehtml%
    </div>
    <script>
        (() => {
            let api = true;
            let DataSource = [];
            let _pageCache = {};
            let _currentKeyword = "";
            let dataStore_%GridColumnName% = null;
            let _showtoolbarGrid_' + ISNULL(@UID_Grid, '') + N' = true;
            let _showtoolbarAdd_' + ISNULL(@UID_Grid, '') + N' = true;

            // ============================================================
            // 0. KHAI BAO CAC HAM SU KIEN MAC DINH CHO GRID
            // ============================================================
            function add%PKColumnName%() {
                console.log("Ham add%PKColumnName% chua duoc dinh nghia.");
            };
            function openDetail%PKColumnName%(rowData) {
                console.log("Ham openDetail%PKColumnName% chua duoc dinh nghia. Data:", rowData);
            };

            // ============================================================
            // 1. KHỞI TẠO DATASTORE DUY NHẤT MỘT LẦN
            // ============================================================
            dataStore_%GridColumnName% = new DevExpress.data.CustomStore({
                key: "%PKColumnName%",
                load: function(loadOptions) {
                    const deferred = $.Deferred();

                        if (!api) {
                        const results = DataSource || [];
                        const skip = loadOptions.skip || 0;
                        const take = loadOptions.take || 50;
                        const pageData = results.slice(skip, skip + take);
                        deferred.resolve({
                            data: pageData,
                    totalCount: results.length
                        });
                        api = true;
                        return deferred.promise();
                    }

                    let params = [];
                    // SP nghiệp vụ
                    params.push("@ProcName", "%SPLoadData%");

                    // Tham số của tên thủ tục load Data
                    let procParam = "@LoginID = " + (window.UserID || window.LoginID) + ", @LanguageID = " + window.LanguageID;

                    params.push("@ProcParam", procParam);

                    // Phân trang
                    params.push("@Take", loadOptions.take || 50);
                    params.push("@Skip", loadOptions.skip || 0);

                    // TotalCount
                    if (loadOptions.requireTotalCount) {
                        params.push("@RequireTotalCount", 1);
                    }

                    // Sort
                    const sort = loadOptions.sort
                        ? loadOptions.sort.map(s => s.selector + (s.desc ? " DESC" : " ASC")).join(",")
                        : "";

                    params.push("@Sort", sort != "" ? "ORDER BY " + sort : "");

                    // Search
                    if (_currentKeyword) {
      params.push("@SearchValue", _currentKeyword);
                        params.push("@ColumnSearch", "");
                    }

                    // Filter
                    if (loadOptions.filter) {
                          // Kiểm tra filter item có phải function không
                          const isJSFunction = (item) => typeof item === "function";

                          const hasFunction = JSON.stringify(loadOptions.filter, (key, val) => {
                              if (typeof val === "function") return "FUNCTION";
       return val;
                          }).includes("FUNCTION");

                          if (!hasFunction) {
                              params.push("@Filters", createConditionQuery(loadOptions.filter));
                          }
                      }

               // Summary
                    if (loadOptions.totalSummary) {
                        const summary = loadOptions.totalSummary.map(item => {
                            const type = item.summaryType === "custom"
                                ? `count(CASE WHEN [${item.selector}] = 1 THEN 1 END) as ${item.selector}_COUNT`
                                : `${item.summaryType}([${item.selector}]) as ${item.selector}_${item.summaryType.toUpperCase()}`;
                            return type;
                        });
                        params.push("@TotalSummary", summary.join(", "));
                   }

                    AjaxHPAParadise({
                        data: {
                            name: "sp_LoadGridUsingAPI",
                            param: params
                        },
                        success: function (res) {
                            const json = typeof res === "string" ? JSON.parse(res) : res;
                            const results = Array.isArray(json?.data?.[0]) ? json.data[0] : [];
                            let result = { data: results };

                            if (loadOptions.requireTotalCount) {
                                result.totalCount = json?.data?.[1]?.[0]?.TotalCount ?? 0;
                                if (loadOptions.totalSummary) {
                                    result.summary = Object.values(json?.data?.[2]?.[0] ?? {});
                                }
                            } else {
                                if (loadOptions.totalSummary) {
                                    result.summary = Object.values(json?.data?.[1]?.[0] ?? {});
                                }
                            }

                            DataSource = results;
                            window.syncSharedGridData("%GridColumnName%");
                            deferred.resolve(result);
                        },
                        error: function (err) {
                            deferred.reject("Data Loading Error");
                        }
                    });

                    return deferred.promise();
                }
            });

            %paradiseloadUI%
            %JS_LOAD_ALL_DATA_SOURCES%
            %JS_CURRENT_ID%

            function clearPageCache() {
                _pageCache = {};
            }

            function getGridHeight() {
                const gridEl = Instance%GridColumnName%%UID%.element();
                const domElement = gridEl.jquery ? gridEl[0] : gridEl;
                const top = domElement.getBoundingClientRect().top;
                return window.innerHeight - top - 20;
            }

            // ============================================================
            // 2. KHỞI TẠO GRID LAYOUT MỘT LẦN DUY NHẤT
            // ============================================================
            const gridInstance = Instance%GridColumnName%%UID%;
            gridInstance.beginUpdate();
            gridInstance.option("remoteOperations", {
                paging: true, filtering: true, sorting: true, searching: true
            });

            gridInstance.option({
                "scrolling.mode": "infinite",
                "scrolling.rowRenderingMode": "virtual",
           "scrolling.preloadEnabled": false,
            "paging.enabled": true,
     "paging.pageSize": 50,
                "pager.visible": false,
                "searchPanel.highlightSearchText": false,
     "dataSource": dataStore_%GridColumnName%,
                "height": getGridHeight()
            });

            gridInstance.option("onOptionChanged", function (e) {
                if (e.name === "searchPanel" && e.fullName === "searchPanel.text") {
                    _currentKeyword = (e.value || "").trim();
                    _pageCache = {};
                }
          });
            gridInstance.endUpdate();

            // ============================================================

            // 3. HÀM RELOAD DATA TỐI GIẢN
            // ============================================================
            function ReloadData(pageNumber, pageSize, keyword = null) {
                if (keyword !== null) _currentKeyword = keyword.trim();
                _pageCache = {};
                gridInstance.refresh();
            }

            %paradiseloadData%

            ReloadData()
        })();
</script>'

	DECLARE @executeLoadDataSource_Fix NVARCHAR(MAX) = '';

	SELECT @executeLoadDataSource_Fix +=
		'if (Instance' + ColumnName + UID + '.getDataSource().items().length == 0 && window["DataSource_' + ColumnName + '"].length > 0) { ' +
		'Instance' + ColumnName + UID + '.option("dataSource", window["DataSource_' + ColumnName + '"]); } ' + CHAR(13) + CHAR(10)
	FROM tblCommonControlType_Signed
	WHERE TableName = ISNULL(@TableName, '')
		AND ISNULL(Layout,'') <> 'Grid_View'
		AND Type IN ('hpaControlSelectBox', 'hpaControlTagBox', 'hpaControlSelectEmployee');

    -- Thay thế placeholders
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%TableName%', ISNULL(@TableName, ''))
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%ColumnName%', ISNULL(@ColumnName, ''))
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%GridColumnName%', ISNULL(@GridColumnName, ''))
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%SPLoadData%', ISNULL(@SPLoadData, ''))
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%UseLayout%', CAST(@UseLayout AS VARCHAR(1)))
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%jsLayoutHandling%', @jsLayoutHandling)
 SET @nsqlHtml = REPLACE(@nsqlHtml, '%JS_CURRENT_ID%', @jsCurrentRecordID);
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%JS_HANDLE_RECORD%', @jsHandleRecord);
   SET @nsqlHtml = REPLACE(@nsqlHtml, '%JS_LOAD_ALL_DATA_SOURCES%', @jsLoadAllDataSources);
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%UID%', ISNULL(@UID, ''))
	SET @nsqlHtml = REPLACE(@nsqlHtml, '%executeLoadDataSource_Fix%', ISNULL(@executeLoadDataSource_Fix, ''))
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%PKColumnName%', ISNULL(@PKColumnNameHtml, 'ID'))

    -- ============================================================================
    -- BUILD HTML PROCEDURE VERSION (với dynamic SQL)
    -- ============================================================================
    DECLARE @html NVARCHAR(MAX) = N''
    DECLARE @loadUI NVARCHAR(MAX) = N''
    DECLARE @loadData NVARCHAR(MAX) = N''

    -- Build dynamic SQL để lấy từ database
    SELECT
        @html += ISNULL(html, ''),

        @loadUI += ISNULL('
    +(select loadUI from tblCommonControlType_Signed where UID = '''+UID+''')', ''),
        @loadData += ISNULL('
        +(select loadData from tblCommonControlType_Signed where UID = '''+UID+''')', '')
    FROM #temptable

    SET @nsqlHtml = REPLACE(@nsqlHtml, '%paradisehtml%', ISNULL(@html, ''))
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%paradiseloadUI%', ''''+ISNULL(@loadUI, '') + ' +N''')
    SET @nsqlHtml = REPLACE(@nsqlHtml, '%paradiseloadData%', ''''+ISNULL(@loadData, '') + ' +N''')

    -- ============================================================================
    -- CẬP NHẬT LẠI VÀO DATABASE
    -- ============================================================================

    UPDATE t
    SET html = tt.html,
        loadUI = tt.loadUI,
        loadData = tt.loadData
    FROM tblCommonControlType_Signed t
    INNER JOIN #temptable tt ON tt.ID = t.ID

    WHERE tt.TableName = @TableName

    -- ============================================================================
    -- RETURN KẾT QUẢ
    -- @nsqlHtml: HTML với dynamic SQL (dùng cho sp_GenerateHTMLScript)
    -- ============================================================================
    SELECT @nsqlHtml AS htmlProc
END
GO