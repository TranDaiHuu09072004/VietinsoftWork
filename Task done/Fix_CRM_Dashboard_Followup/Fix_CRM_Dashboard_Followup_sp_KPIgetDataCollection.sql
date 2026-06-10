ALTER PROCEDURE [dbo].[sp_KPIgetDataCollection](
    @LoginID INT,
    @FromDate DATETIME = null,
    @ToDate DATETIME = null,
    @LanguageID VARCHAR(5) = 'VN',
    @EmployeeID VARCHAR(MAX) = '',
    @isViewAll bit = 0,
    @PageNumber int = 0, -- khong dung
    @PageSize int = 50,
    @Keyword NVARCHAR(200) = '',
    @isDuLieuTinhKPI bit = 0,
    @TempTableAPIName nvarchar(100) = '',
    @activeTab varchar(10) = null,
    @activeStatus int = null
)
AS
BEGIN
    SET NOCOUNT ON;

    CREATE TABLE #tmpEmployeeList(
        EmployeeID VARCHAR(30),
        FullName NVARCHAR(200)
    );

IF OBJECT_ID('tempdb..#tmpData1') IS NOT NULL DROP TABLE #tmpData1;
IF OBJECT_ID('tempdb..#tmpData2') IS NOT NULL DROP TABLE #tmpData2;
IF OBJECT_ID('tempdb..#tmpData3') IS NOT NULL DROP TABLE #tmpData3;
IF OBJECT_ID('tempdb..#tmpData4') IS NOT NULL DROP TABLE #tmpData4;

    INSERT INTO #tmpEmployeeList(EmployeeID, FullName)
    EXEC sp_getEmployeeListWithPermission @LoginID;

    CREATE TABLE #tmpFilterEmployees(
        EmployeeID VARCHAR(30)
    );

    IF @EmployeeID IS NOT NULL AND LTRIM(RTRIM(@EmployeeID)) <> ''
    BEGIN
        INSERT INTO #tmpFilterEmployees(EmployeeID)
        SELECT LTRIM(RTRIM(value)) AS EmployeeID
        FROM STRING_SPLIT(@EmployeeID, ',')
        WHERE LTRIM(RTRIM(value)) <> '';
    END

    SELECT
    CRM_CompanyID,
    TRIM(',' FROM TRIM(STRING_AGG(NULLIF(LTRIM(RTRIM(ci.FullName)), ''), ', ')))    AS FullName,
    TRIM(',' FROM TRIM(STRING_AGG(NULLIF(LTRIM(RTRIM(ci.PhoneNumber)), ''), ', '))) AS PhoneNumbers,
    TRIM(',' FROM TRIM(STRING_AGG(NULLIF(LTRIM(RTRIM(ci.Email)), ''), ', ')))       AS Emails,
    TRIM(',' FROM TRIM(STRING_AGG(NULLIF(LTRIM(RTRIM(ci.Email1)), ''), ', ')))       AS Email1s,
    TRIM(',' FROM TRIM(STRING_AGG(NULLIF(LTRIM(RTRIM(ci.PhoneNumber1)), ''), ', ')))       AS PhoneNumber1s,
    TRIM(',' FROM TRIM(STRING_AGG(NULLIF(LTRIM(RTRIM(CAST(isnull(ci.StatusID,7) AS VARCHAR(10)))), ''), ', '))) AS StatusID
    INTO #tmptblCRM_CustomerPersonInfo
    FROM tblCRM_CustomerPersonInfo ci left join tblCRM_CustomerOwner o on ci.CRM_CustomerID = o.CRM_CustomerID
    inner JOIN #tmpEmployeeList te
        ON o.OwnerID = te.EmployeeID
    WHERE ci.CRM_CompanyID IS NOT NULL
    AND (
    @EmployeeID = ''
    OR o.OwnerID IN (SELECT EmployeeID FROM #tmpFilterEmployees)
    )
    GROUP BY CRM_CompanyID;

    if @isDuLieuTinhKPI = 1 OR @activeStatus = 3
    begin
     SELECT DISTINCT
            CAST(cc.Company_ID AS VARCHAR) AS RowID,
            cc.Company_ID, cc.TaxCode, cc.Company,
            cc.Industry_ID, ci.IndustryName, cc.Address,
            cc.CompanySize_ID, cs.CompanyName AS CompanySize,
            cp.CreatedDate, cc.Source,
            cp.FullName, cp.PhoneNumber AS PhoneNumber, cp.Email AS Email,cp.PhoneNumber1 AS PhoneNumber1,cp.Email1 AS Email1,
            cc.InchargePerson,cc.IP_Phone,cc.IP_Email,
            isnull(cp.StatusID,7) as StatusID,cp.CRM_CustomerID
        into #tmpData1
        FROM tblCRM_CompanyInfo cc
        inner JOIN tblCRM_CustomerPersonInfo cp  ON cp.CRM_CompanyID = cc.Company_ID
        left join tblCRM_CustomerOwner o on cp.CRM_CustomerID = o.CRM_CustomerID
        inner join #tmpEmployeeList tl on tl.EmployeeID = o.OwnerID
        LEFT JOIN tblCRM_Industry ci ON ci.ID = cc.Industry_ID
        LEFT JOIN tblCRM_CompaySize cs ON cs.CompanyID = cc.CompanySize_ID
        LEFT JOIN (
            SELECT
                CRM_CustomerID,
                MIN(CreateDate) AS FirstTimeContact,
                MAX(CreateDate) AS LastTimeContact
            FROM tblCRM_NotesHistory
            GROUP BY CRM_CustomerID
        ) nh ON nh.CRM_CustomerID = cp.CRM_CustomerID

        WHERE
         (
              (isnull(@activeStatus,7) <> 3 and (@isViewAll = 1 or
      (CAST(cp.CreatedDate AS DATE) >= CAST(@FromDate AS DATE)
                AND CAST(cp.CreatedDate AS DATE) <= CAST(@ToDate AS DATE))) )
                or (
                   (
                    @activeStatus = 3
                    AND CAST(COALESCE(nh.LastTimeContact, nh.FirstTimeContact, cp.UpdateTime, cp.CreatedDate) AS DATE) >= CAST(@FromDate AS DATE)
                    AND CAST(COALESCE(nh.LastTimeContact,nh.FirstTimeContact ,cp.UpdateTime, cp.CreatedDate) AS DATE) <= CAST(@ToDate AS DATE)
                    )
                ))
            AND
            ((@isDuLieuTinhKPI = 1 and isnull(IsPrimary,0) = 1 ) or @isDuLieuTinhKPI = 0)
            and (@activeStatus is null or cp.StatusID = @activeStatus)
            and (o.OwnerID in (SELECT EmployeeID FROM #tmpFilterEmployees) or @EmployeeID = '')
            and (@isDuLieuTinhKPI = 1 AND cp.PhoneNumber is not null OR @isDuLieuTinhKPI = 0)
    end
    else
    IF EXISTS (SELECT 1 FROM #tmpFilterEmployees)
    BEGIN

        SELECT
            CAST(cc.Company_ID AS VARCHAR) AS RowID,
            cc.Company_ID, cc.TaxCode, cc.Company,
            cc.Industry_ID, ci.IndustryName, cc.Address,
            cc.CompanySize_ID, cs.CompanyName AS CompanySize,
            cc.CreatedDate, cc.Source,
            cp.FullName, cp.PhoneNumbers AS PhoneNumber, cp.Emails AS Email,
            cp.PhoneNumber1s as PhoneNumber1, cp.Email1s as Email1,
            cc.InchargePerson,cc.IP_Email,cc.IP_Phone,
            isnull(cp.StatusID,7) as StatusID
            into #tmpData2
        FROM tblCRM_CompanyInfo cc
        INNER JOIN #tmptblCRM_CustomerPersonInfo cp ON cp.CRM_CompanyID = cc.Company_ID
        LEFT JOIN tblCRM_Industry ci ON ci.ID = cc.Industry_ID
        LEFT JOIN tblCRM_CompaySize cs ON cs.CompanyID = cc.CompanySize_ID
        WHERE
            (@isViewAll = 1
            OR (@isViewAll = 0
                AND CAST(cc.CreatedDate AS DATE) >= CAST(@FromDate AS DATE)
                AND CAST(cc.CreatedDate AS DATE) <= CAST(@ToDate AS DATE)))
                AND (@activeStatus is null or exists (select 1 from string_split(isnull(cp.StatusID,7),',') where trim(value) = @activeStatus))
    END
    ELSE
    BEGIN

        SELECT
            CAST(cc.Company_ID AS VARCHAR) AS RowID,
            cc.Company_ID, cc.TaxCode, cc.Company,
            cc.Industry_ID, ci.IndustryName, cc.Address,
            cc.CompanySize_ID, cs.CompanyName AS CompanySize,
            cc.CreatedDate, cc.Source,
            cp.FullName, cp.PhoneNumbers AS PhoneNumber, cp.Emails AS Email,
            cp.PhoneNumber1s as PhoneNumber1, cp.Email1s as Email1,
            cc.InchargePerson,cc.IP_Email,cc.IP_Phone,isnull(cp.StatusID,7) as StatusID
            into #tmpData3
        FROM tblCRM_CompanyInfo cc
        LEFT JOIN #tmptblCRM_CustomerPersonInfo cp ON cp.CRM_CompanyID = cc.Company_ID
        LEFT JOIN tblCRM_Industry ci ON ci.ID = cc.Industry_ID
        LEFT JOIN tblCRM_CompaySize cs ON cs.CompanyID = cc.CompanySize_ID
        WHERE
            (@isViewAll = 1
            OR (@isViewAll = 0
                AND CAST(cc.CreatedDate AS DATE) >= CAST(@FromDate AS DATE)
                AND CAST(cc.CreatedDate AS DATE) <= CAST(@ToDate AS DATE)))
                AND (@activeStatus is null or exists (select 1 from string_split(isnull(cp.StatusID,7),',') where trim(value) = @activeStatus))
    END

     DECLARE @sql nvarchar(max) = '';

        IF OBJECT_ID('tempdb..#tmpData1') IS NOT NULL
        BEGIN
            SET @sql = N'SELECT * FROM #tmpData1';
        END
        ELSE IF OBJECT_ID('tempdb..#tmpData2') IS NOT NULL
        BEGIN
            SET @sql = N'SELECT * FROM #tmpData2';
        END
        ELSE IF OBJECT_ID('tempdb..#tmpData3') IS NOT NULL
        BEGIN
            SET @sql = N'SELECT * FROM #tmpData3';
        END
        ELSE IF OBJECT_ID('tempdb..#tmpData4') IS NOT NULL
        BEGIN
            SET @sql = N'SELECT * FROM #tmpData4';
        END

    IF ISNULL(@TempTableAPIName, '') <> ''
 EXEC(N'SELECT * INTO ' + @TempTableAPIName + N' FROM (' + @sql + N') _t ORDER BY isnull(CreatedDate,getDate()) DESC');
    ELSE
        EXEC(@sql);

    DROP TABLE #tmpEmployeeList;
END
