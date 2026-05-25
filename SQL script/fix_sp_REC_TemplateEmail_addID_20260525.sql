/* =============================================================================
   fix_sp_REC_TemplateEmail_addID_20260525.sql
   ---------------------------------------------------------------------------
   Mục đích : Fix lỗi runtime
                ❌ Uncaught ReferenceError: addID is not defined
              khi user click icon "+" trên menu MnuREC048 "Quản lý Template Email"
              (ClassName = sp_REC_TemplateEmail, renderer = sp_REC_TemplateEmail_html).

   Phân tích :
      1. Renderer sp_REC_TemplateEmail_html dùng nhánh config-driven
         (tblCommonControlType_Signed UID = P8792B49BD85E42D9A99D14A5F0227DA8,
          ColumnIDName = 'ID', GridName = 'GridTemplateEmailList').
      2. Toolbar do `loadUI` framework sinh bind nút "+" → gọi
         `add<ColumnIDName>()` = `addID()`; bind row click → gọi
         `openDetail<ColumnIDName>(obj)` = `openDetailID(obj)`.
      3. Source renderer hiện tại KHÔNG khai báo 2 function này
         → click "+" / click row raise ReferenceError.

   Chuẩn ParadiseHR — tham chiếu pattern từ sp_CRM_ProductType_html
   (canonical, đã verify production):
      - Function `add<ColumnIDName>()`:
            window.currentClickedGrid<GridName>  = null;
            window.currentClicked_Grid<GridName> = null;
            if (mobileOS) OpenFormParamMobile(`<TargetClassName>`);
            else          openFormParam(`<TargetClassName>`);
      - Function `openDetail<ColumnIDName>(obj)`:
            window.currentClickedGrid<GridName>  = obj;
            if (mobileOS) OpenFormParamMobile(`<TargetClassName>`);
            else          openFormParam(`<TargetClassName>`);
      - KHÔNG tự gọi AjaxHPAParadise + showEditPopupHTML — framework lo modal.

   Mapping cho menu này:
      GridName       = TemplateEmailList
      ColumnIDName   = ID
      TargetClassName= sp_REC_EditTemplateEmailType  (= ClassName của MnuREC033
                       theo yêu cầu user; framework resolve form qua menu metadata)

   ⚠️ Lưu ý: Procedure `sp_REC_EditTemplateEmailType` hiện chưa tồn tại trong
   sys.objects ở DB Paradise_Dev (chỉ có cache HTML cùng tên). MnuREC033 vẫn
   trỏ ClassName này. Nếu sau khi fix vẫn lỗi khi mở modal, cần fix riêng
   MnuREC033 (align ClassName về `sp_REC_EditTemplateEmail` — proc tồn tại
   thật + có cache, ĐÚNG chức năng edit Template Email).

   Database : Paradise_Dev (SVRVTS01\SQL2022).
   Idempotent: CREATE OR ALTER procedure + DELETE+EXEC sp_GenerateHTMLScript.
   Khuyến cáo: BACKUP DB trước khi chạy. Logout/login để client lấy cache mới.
   ============================================================================= */

SET NOCOUNT ON;
SET ANSI_NULLS ON;
SET QUOTED_IDENTIFIER ON;
GO

PRINT N'================================================================';
PRINT N' FIX sp_REC_TemplateEmail_html — bổ sung addID / openDetailID';
PRINT N'================================================================';
GO

CREATE OR ALTER PROCEDURE [dbo].[sp_REC_TemplateEmail_html]
(
    @LoginID    INT          = 3,
    @LanguageID VARCHAR(2)   = 'VN'
)
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @html NVARCHAR(MAX) = N'';

    SET @html = N'
   <div id="sp_REC_TemplateEmail_html">
    <div id="GridTemplateEmailList" style="height: 100%"></div>
</div>

<script>
(() => {
    let api = true;
    let DataSource = [];
    let _pageCache = {};
    let _currentKeyword = "";

    let dataStore_GridTemplateEmailList = null;
    let _showtoolbarGrid_P8792B49BD85E42D9A99D14A5F0227DA8 = true;

    /* ============================================================
       TOOLBAR + ROW CLICK CALLBACK  (chuẩn ParadiseHR — pattern
       copy từ sp_CRM_ProductType_html: openFormParam / OpenFormParamMobile)

       PHẢI khai báo TRƯỚC khi nạp loadUI để toolbar binding (do loadUI sinh)
       nhìn thấy 2 function này qua closure scope của IIFE.
       ============================================================ */
    function addID() {
        window.currentClickedGridTemplateEmailList  = null;
        window.currentClicked_GridTemplateEmailList = null;

        if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
            OpenFormParamMobile(`sp_REC_EditTemplateEmailType`);
        } else {
            openFormParam(`sp_REC_EditTemplateEmailType`);
        }
    }

    function openDetailID(obj) {
        window.currentClickedGridTemplateEmailList = obj;

        if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
            OpenFormParamMobile(`sp_REC_EditTemplateEmailType`);
        } else {
            openFormParam(`sp_REC_EditTemplateEmailType`);
        }
    }

    /* ============================================================
       1. KHỞI TẠO DATASTORE DUY NHẤT MỘT LẦN
       ============================================================ */
    dataStore_GridTemplateEmailList = new DevExpress.data.CustomStore({
        key: "ID",
        load: function (loadOptions) {
            const deferred = $.Deferred();

            if (!api) {
                const results = DataSource || [];
                const skip = loadOptions.skip || 0;
                const take = loadOptions.take || 50;
                const pageData = results.slice(skip, skip + take);
                deferred.resolve({ data: pageData, totalCount: results.length });
                api = true;
                return deferred.promise();
            }

            let params = [];
            params.push("@ProcName", "sp_REC_TemplateEmailList");
            let procParam = "@LoginID = " + (window.UserID || window.LoginID)
                          + ", @LanguageID = " + window.LanguageID;
            params.push("@ProcParam", procParam);

            params.push("@Take", loadOptions.take || 50);
            params.push("@Skip", loadOptions.skip || 0);

            if (loadOptions.requireTotalCount) params.push("@RequireTotalCount", 1);

            const sort = loadOptions.sort
                ? loadOptions.sort.map(s => s.selector + (s.desc ? " DESC" : " ASC")).join(",")
                : "STT";
            params.push("@Sort", "ORDER BY " + sort);

            if (_currentKeyword) {
                params.push("@SearchValue",  _currentKeyword);
                params.push("@ColumnSearch", "");
            }

            if (loadOptions.filter) {
                const hasFunction = JSON.stringify(loadOptions.filter, (k, v) =>
                    (typeof v === "function") ? "FUNCTION" : v
                ).includes("FUNCTION");
                if (!hasFunction) {
                    params.push("@Filters", createConditionQuery(loadOptions.filter));
                }
            }

            if (loadOptions.totalSummary) {
                const summary = loadOptions.totalSummary.map(item => {
                    return item.summaryType === "custom"
                        ? `count(CASE WHEN [${item.selector}] = 1 THEN 1 END) as ${item.selector}_COUNT`
                        : `${item.summaryType}([${item.selector}]) as ${item.selector}_${item.summaryType.toUpperCase()}`;
                });
                params.push("@TotalSummary", summary.join(", "));
            }

            AjaxHPAParadise({
                data: { name: "sp_LoadGridUsingAPI", param: params },
                success: function (res) {
                    const json    = typeof res === "string" ? JSON.parse(res) : res;
                    const results = Array.isArray(json?.data?.[0]) ? json.data[0] : [];
                    let result = { data: results };

                    if (loadOptions.requireTotalCount) {
                        result.totalCount = json?.data?.[1]?.[0]?.TotalCount ?? 0;
                        if (loadOptions.totalSummary)
                            result.summary = Object.values(json?.data?.[2]?.[0] ?? {});
                    } else if (loadOptions.totalSummary) {
                        result.summary = Object.values(json?.data?.[1]?.[0] ?? {});
                    }

                    DataSource = results;
                    window.syncSharedGridData("GridTemplateEmailList");
                    deferred.resolve(result);
                },
                error: function () { deferred.reject("Data Loading Error"); }
            });

            return deferred.promise();
        }
    });

    '
    + ISNULL(CAST((
        SELECT loadUI FROM tblCommonControlType_Signed
        WHERE UID = 'P8792B49BD85E42D9A99D14A5F0227DA8'
    ) AS NVARCHAR(MAX)), N'') + N'

    window.currentRecordID_ID = null;

    function clearPageCache() {
        _pageCache = {};
    }

    function getGridHeight() {
        const gridEl    = InstanceGridTemplateEmailListP8792B49BD85E42D9A99D14A5F0227DA8.element();
        const domEl     = gridEl.jquery ? gridEl[0] : gridEl;
        const top       = domEl.getBoundingClientRect().top;
        return window.innerHeight - top - 20;
    }

    /* ============================================================
       2. KHỞI TẠO GRID LAYOUT MỘT LẦN DUY NHẤT
       ============================================================ */
    const gridInstance = InstanceGridTemplateEmailListP8792B49BD85E42D9A99D14A5F0227DA8;

    gridInstance.beginUpdate();
    gridInstance.option("remoteOperations", {
        paging: true, filtering: true, sorting: true, searching: true
    });
    gridInstance.option({
        "scrolling.mode":              "infinite",
        "scrolling.rowRenderingMode":  "virtual",
        "scrolling.preloadEnabled":    false,
        "paging.enabled":              true,
        "paging.pageSize":             50,
        "pager.visible":               false,
        "searchPanel.highlightSearchText": false,
        "dataSource":                  dataStore_GridTemplateEmailList,
        "height":                      getGridHeight()
    });

    gridInstance.option("onOptionChanged", function (e) {
        if (e.name === "searchPanel" && e.fullName === "searchPanel.text") {
            _currentKeyword = (e.value || "").trim();
            _pageCache = {};
        }
    });
    gridInstance.endUpdate();

    /* ============================================================
       3. HÀM RELOAD DATA
       ============================================================ */
    function ReloadData(pageNumber, pageSize, keyword = null) {
        if (keyword !== null) _currentKeyword = keyword.trim();
        _pageCache = {};
        gridInstance.refresh();
    }

    '
    + ISNULL(CAST((
        SELECT loadData FROM tblCommonControlType_Signed
        WHERE UID = 'P8792B49BD85E42D9A99D14A5F0227DA8'
    ) AS NVARCHAR(MAX)), N'') + N'

    ReloadData();

})();
</script>
   ';

    SELECT @html AS html;
    --EXEC sptblCommonControlType_Signed_DUC 'sp_REC_TemplateEmail_html'
    --EXEC sp_GenerateHTMLScript_new 'sp_REC_TemplateEmail_html'
END
GO

PRINT N'  [OK] sp_REC_TemplateEmail_html đã được ALTER.';
GO

/* =============================================================================
   PHASE 2 — Rebuild cache tblHtmlScriptCache cho sp_REC_TemplateEmail_html
   ============================================================================= */
PRINT N'PHASE 2: Rebuild HTML cache...';
GO

BEGIN TRY
    BEGIN TRANSACTION;

    DELETE FROM dbo.tblHtmlScriptCache WHERE TableName = N'sp_REC_TemplateEmail_html';
    EXEC dbo.sp_GenerateHTMLScript 'sp_REC_TemplateEmail_html';

    COMMIT TRANSACTION;
    PRINT N'  [OK] Cache rebuilt.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    DECLARE @err nvarchar(max) = ERROR_MESSAGE();
    PRINT N'  [LỖI] ' + @err;
    THROW;
END CATCH
GO

/* =============================================================================
   VERIFY
   ============================================================================= */
PRINT N'';
PRINT N'================================================================';
PRINT N' VERIFY';
PRINT N'================================================================';
GO

SELECT TableName, LanguageID, ScreenType, DATALENGTH(html) AS HtmlBytes
FROM dbo.tblHtmlScriptCache
WHERE TableName = N'sp_REC_TemplateEmail_html'
ORDER BY LanguageID;

SELECT o.name, o.modify_date, DATALENGTH(OBJECT_DEFINITION(o.object_id)) AS DefBytes
FROM sys.objects o
WHERE o.name = N'sp_REC_TemplateEmail_html';

PRINT N'';
PRINT N'>>> HOÀN TẤT.';
PRINT N'    Logout/login client để lấy cache mới.';
PRINT N'    Test: mở MnuREC048 → click "+" → mở MnuREC033 dạng modal.';
PRINT N'    Test: click 1 row trong grid → mở MnuREC033 với dữ liệu row qua';
PRINT N'          window.currentClickedGridTemplateEmailList.';
GO
