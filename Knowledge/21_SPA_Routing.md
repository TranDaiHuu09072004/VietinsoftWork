# 21 — SPA Routing & Parameter Passing

Reference: [07_menu_system.md](07_menu_system.md) (Menu structure), [14_ParadiseStyle.md](14_ParadiseStyle.md) (UI guidelines).

ParadiseHR operates as a Single Page Application (SPA). Screen transitions and parameter passing are managed via global routing helpers.

## 1. Cross-Platform Transition
Check the user device type using `getMobileOperatingSystem()` and call the platform-specific routing API:
```javascript
let paramData = { currentID: 2, action: "edit" };
let targetForm = "sp_CRM_EditProductType"; // Destination page name (omit '_html' suffix)

if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
    OpenFormParamMobile(targetForm, paramData);
} else {
    openFormParam(targetForm, paramData);
}
```

## 2. Ingesting Parameters in Destination Page
Upon load, the framework automatically registers and populates a global object named:
`window.<targetForm>_param`
*Usage inside the destination page script*:
```javascript
// Access parameters directly
let id = window.sp_CRM_EditProductType_param.currentID;
```

## 3. DataGrid Navigation Pattern
For interactive grids configured with `IsOpenDetailRowGrid = 1`, declare this trigger template:
```javascript
// Triggers when a grid row is clicked (using primary key Column ID name, e.g. TemplateName)
window.openDetailTemplateName = function(rowData) {
    let targetForm = "sp_REC_EmailTemplateDetail";
    let paramData = { TemplateName: rowData.TemplateName };

    if (["Android", "iOS"].includes(getMobileOperatingSystem())) {
        OpenFormParamMobile(targetForm, paramData);
    } else {
        openFormParam(targetForm, paramData);
    }
};
```

## 4. Prerequisite: Hidden Menu Registration
To allow the router to resolve the destination page, the page **must** be registered in the localization messages and menu tables (even if excluded from the main navigation sidebar tree):
```sql
-- 1. Create localization labels
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'sp_REC_GridTest_Detail')
    INSERT INTO tblMD_Message (MessageID, Language, Content) 
    VALUES ('sp_REC_GridTest_Detail', 'VN', N'Form Detail'), ('sp_REC_GridTest_Detail', 'EN', 'Form Detail');

-- 2. Register hidden menu under a valid parent (e.g. MnuREC001)
IF NOT EXISTS (SELECT 1 FROM MEN_Menu WHERE ClassName = 'sp_REC_GridTest_Detail')
    INSERT INTO MEN_Menu (MenuID, ParentMenuID, ClassName, Priority, IsWeb, Activity, showDialog, AssemblyName, IsVisible, Separation)
    VALUES ('sp_REC_GridTest_Detail', 'MnuREC001', 'sp_REC_GridTest_Detail', 999, 1, 'DataSettingListViewActivity', 0, 'DataSetting', 1, 1);
```
