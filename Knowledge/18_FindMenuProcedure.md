# 18 — Skill: Finding Menu Stored Procedures

Reference: [07_menu_system.md](07_menu_system.md) (Menu structure), [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) (Secure rendering).

Use this workflow when requested to identify a menu's backing database procedures, debug layout issues, or modify a screen's UI.

```
[1] Translate Search (tblMD_Message) -> [2] Map Menu (MEN_Menu) -> [3] Extract ClassName -> [4] Verify Object (sys.objects) -> [5] Locate Renderer (sys.objects for %_html)
```

---

## 1. Five-Step Lookup Sequence

### Step 1: Locate Menu in Messages
Query the language localizer to obtain the `MenuID`. Focus on entries starting with `Mnu%` to filter out label noise.
```sql
SELECT TOP 20 MessageID, Language, Content
FROM tblMD_Message
WHERE Content LIKE N'%<Menu_Name_VN>%' AND MessageID LIKE 'Mnu%' AND Language = 'VN';
```

### Step 2: Query Menu Metadata
Using the resolved `MessageID` (which maps to `MenuID`), fetch flags and assemblies from `MEN_Menu`:
```sql
SELECT MenuID, ClassName, AssemblyName, ParentMenuID, IsVisible, IsWeb, ViewOnWeb, isShowLayOutWeb, IsUseMobileDevice, glyphicon, URL
FROM MEN_Menu WHERE MenuID = '<Resolved_MenuID>';
```
*Platform Classification based on metadata flags*:
*   **Web HTML-rendered**: `AssemblyName = 'DataSetting'` and `IsUseMobileDevice = 1`. Backed by an active `_html` procedure.
*   **Desktop Grid**: `AssemblyName = 'DataSetting'` and Web/Mobile flags are `0`. Backed by a View or Procedure.
*   **Custom .NET Form**: `AssemblyName = 'HPA.*'`. Coded inside the application client binaries; no matching DB views/procs exist.

### Step 3: Extract ClassName
`ClassName` points to the underlying data source: a Stored Procedure (usually `sp_*`), a View (usually `vtbl*` or `v*`), or a .NET Class FQN.

### Step 4: Verify Object Existence
Check if `ClassName` exists in the active database schema:
```sql
SELECT name, type_desc, modify_date FROM sys.objects
WHERE name = '<ClassName>' AND type IN ('P','V','U');
```
*Analysis*:
*   `SQL_STORED_PROCEDURE` (`P`): Proceed to Step 5 to find its HTML renderer.
*   `VIEW` (`V`) / `USER_TABLE` (`U`): Managed via `tblDataSetting` parameters. No `_html` renderer is generated.
*   *0 rows returned*: Custom .NET Form or deprecated item.

### Step 5: Locate HTML Renderer Procedure
For Web HTML-rendered menus, find the corresponding renderer proc:
```sql
SELECT name, type_desc, modify_date FROM sys.objects
WHERE name = '<ClassName>' + '_html' AND type = 'P';
```
*Rebuild Cache after edits*:
```sql
EXEC sp_GenerateHTMLScript '<ClassName>_html';
```

---

## 2. Integrated Consolidation Batch
Execute this block to complete all steps in a single database roundtrip:
```sql
DECLARE @MenuName NVARCHAR(200) = N'<Exact_Menu_Name>';
DECLARE @MenuID VARCHAR(100), @ClassName VARCHAR(200);

-- 1. Resolve Menu ID
SELECT TOP 1 @MenuID = MessageID FROM tblMD_Message WHERE Content = @MenuName AND MessageID LIKE 'Mnu%' AND Language = 'VN';
SELECT @MenuID AS ResolvedMenuID;

-- 2. Fetch Menu Configuration
SELECT MenuID, ClassName, AssemblyName, IsVisible, IsWeb, ViewOnWeb, IsUseMobileDevice FROM MEN_Menu WHERE MenuID = @MenuID;
SELECT TOP 1 @ClassName = ClassName FROM MEN_Menu WHERE MenuID = @MenuID;

-- 3. Verify backing DB objects
SELECT name, type_desc, modify_date FROM sys.objects WHERE name IN (@ClassName, @ClassName + '_html') ORDER BY name;

-- 4. Check HTML Cache sizing
SELECT TableName, LanguageID, DATALENGTH(html) AS HtmlBytes, Version FROM tblHtmlScriptCache WHERE TableName = @ClassName + '_html' ORDER BY LanguageID;
```

---

## 3. Special Case Resolution
*   **0 Matches at Step 1**: Omit prefixes (e.g. "Đơn", "Bảng") and query again. If still empty, query related synonyms in English/Korean, or query active menu names to suggest options:
    ```sql
    SELECT TOP 30 m.MenuID, msg.Content FROM MEN_Menu m
    INNER JOIN tblMD_Message msg ON msg.MessageID = m.MenuID AND msg.Language = 'VN'
    WHERE msg.Content LIKE N'Search_Keyword%' AND ISNULL(m.IsVisible,0) = 1;
    ```
    *Rule*: Do not guess ClassName. Report results to the user.
*   **View ClassNames**: If `ClassName` is a View, configure column mappings and grids in `tblDataSetting` and `tblDataSettingLayout`.
*   **Wrapper Proc without `_html`**: Verify grid parameters using:
    ```sql
    SELECT TableName, ViewName, IsProcedure, IsShowLayout, FormLayoutJS FROM tblDataSetting WHERE TableName = '<ClassName>';
    ```
