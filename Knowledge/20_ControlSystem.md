---
name: hpa-control-system
description: Full reference for HPA Control System: configuration (tblCommonControlType_Signed), public APIs, callbacks, runtime variables, and integration rules.
---

# HPA Control System Reference

## Part A: Control Creation & Configuration

### 1. `tblCommonControlType_Signed` Schema
| Category | Column | Description / Value |
|---|---|---|
| **Required** | `TableName` | Form/menu Stored Procedure name (e.g., `sp_CRM_CustomerDetail_html`) |
| | `ColumnName` | Target database column to bind |
| | `Type` | Control type (e.g., `hpaControlText`, `hpaControlSelectBox`, etc.) |
| | `AutoSave` | Enable autosave (1=Yes, 0=No [default]) |
| | `ReadOnly` | Enable read-only (1=Yes, 0=No [default]) |
| **Common** | `ColumnIDName` | Primary key of the base table (e.g., `Company_ID`) |
| | `ColumnIDName2` | Secondary primary key (optional) |
| | `TableEditor` | Target table for data saving |
| | `SPLoadData` | SP to fetch grid rows |
| | `DisplayName` | UI Display/Validation Name (e.g., `Customer Name`) |
| | `GridColumnName` | Name of parent grid container (if layout is grid) |
| | `IsRequired` | Field validation constraint (1=Required, 0=Optional [default]) |
| | `TabIndex` | Tab navigation order index |
| | `DataSourceSP` | SP supplying data for SelectBox, TagBox, TextSearch, SelectEmployee |
| | `Layout` | Grid layout mode: `'Grid_View'` (else NULL) |
| **Advanced**| `AllowSorting` / `AllowFiltering` | 1=Enabled, 0=Disabled (Grid only) |
| | `GridWidth` | Column pixel width (e.g., `150`) |
| | `IsMultiSelectEmployee` | Multi-select for `hpaControlSelectEmployee` (1=Multi, 0=Single) |
| | `IsOpenDetailRowGrid` | 1=Click row to open details (Set **only** on grid container row) |
| | `IsMultiSelectRowGrid` | 1=Enable grid row multi-selection |
| | `CustomValidate` | Client-side validation function name |
| | `KeyUpdateGrid` | Key for multi-PK grid row sync |
| | `ColumnNameSync` | Field name for grid sync |
| **Auto-Generated** | `ID`, `html`, `loadUI`, `loadData`, `UID`, `GroupIndex` | **DO NOT INSERT / UPDATE** |

### 2. Control Type Mapping
*   `hpaControlText`: Short text input/display.
*   `hpaControlTextArea`: Multi-line text.
*   `hpaControlRichTextEditorPremium`: Rich editor (replaces deprecated `hpaControlRichTextEditor`).
*   `hpaControlTextSearch`: Server-side autocomplete dropdown. `DataSourceSP` receives `@SearchText`, `@SearchTextNorm`, `@Skip`, `@Take`, and returns results `[{ID, Name}]` and `[{TotalCount: N}]`.
*   `hpaControlSelectBox`: Single-select dropdown.
*   `hpaControlTagBox`: Multi-select tags.
*   `hpaControlSelectEmployee`: Special employee selection.
*   `hpaControlCheckBox`: Boolean (0/1).
*   `hpaControlDate` / `hpaControlDateTime` / `hpaControlTime`: Date, date-time, time.
*   `hpaControlPhone` / `hpaControlNumber` / `hpaControlMoney` / `hpaControlFile`: Specialized inputs.

### 3. Rules for SQL Generation & Cache Update
1. **Validation & Mapping**: Never infer types directly from column names without confirming via `ask_question`. Set `DisplayName` if required, map `TabIndex` sequentially, and set `AutoSave` and `ReadOnly` according to constraints.
2. **ControlGrid Container Row**: To configure a grid on the screen, insert a "container row" first:
   - `ColumnName` = Name of the grid container (matches `GridColumnName` of its columns).
   - `GridColumnName` = **NULL** (Crucial: container row must have NULL parent grid).
   - `Layout` = `'Grid_View'`, `SPLoadData` = Grid fetch SP, `ColumnIDName` = Row key.
3. **Applying Changes**: Always run the compilation and cache update procedures after configuration changes:
   ```sql
   EXEC sptblCommonControlType_Signed_DUC 'sp_TenManHinh_html';
   EXEC sp_GenerateHTMLScript 'sp_TenManHinh_html';
   ```

### 4. SQL Configuration Examples
```sql
-- Example 1: Form Inputs
INSERT INTO tblCommonControlType_Signed (TableName, ColumnIDName, TableEditor, ColumnName, Type, DisplayName, IsRequired, TabIndex, DataSourceSP)
SELECT 'sp_CRM_EditContract_html', 'ContractID', 'tblCRM_Contract', 'ContractName', 'hpaControlText', 'Contract Name', 1, 1, NULL UNION ALL
SELECT 'sp_CRM_EditContract_html', 'ContractID', 'tblCRM_Contract', 'StatusID', 'hpaControlSelectBox', 'Status', 0, 2, 'sp_GetContractStatusList';

-- Example 2: ControlGrid (Container row + Column fields)
INSERT INTO tblCommonControlType_Signed (TableName, SPLoadData, ColumnIDName, ColumnName, Type, Layout, GridColumnName, IsOpenDetailRowGrid)
SELECT 'sp_CRM_CustomerDetail_html', 'sp_CRM_LoadCustomerDetail_lienhe', 'Company_ID', 'GridLienHe', 'hpaControlText', 'Grid_View', NULL, 1;

INSERT INTO tblCommonControlType_Signed (TableName, SPLoadData, ColumnIDName, ColumnName, Type, DisplayName, Layout, GridColumnName)
SELECT 'sp_CRM_CustomerDetail_html', 'sp_CRM_LoadCustomerDetail_lienhe', 'Company_ID', 'ACFullname', 'hpaControlText', '%ACFullname%', 'Grid_View', 'GridLienHe';
```

---

## Part B: Frontend Integration & JavaScript APIs

### 1. Control Lifecycle & Injecting Scripts
Each control generates `html` (container `div`), `loadUI` (DevExtreme setup), and `loadData` (data binding). Inject them into the main HTML SP:
```sql
SET @html = @html + N'<script>(async () => {'
  + (SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = 'CONTROL_UID_1')
  + (SELECT loadUI FROM tblCommonControlType_Signed WHERE UID = 'CONTROL_UID_2')
  + N'// Custom script here...
})();</script>'
```

### 2. Control Instance APIs
Use `Instance<ColumnName><UID>` to invoke methods.
*   **Standard Controls**: `.getValue()`, `.setValue(val)`, `.option(name, value)`, `.repaint()`, `.clearValidationError()`.
*   **DataSource Widgets**: SelectBox/TagBox offer `.getDataSource()`, `._suppressValueChangeAction()`, and `._resumeValueChangeAction()`.
*   **hpaControlTextSearch**: `.getSelectedItem()`, `.getSelectedID()`, `.focus()`, `.rebindInputEvent()`.
*   **hpaControlSelectEmployee**: `.getValue()` returns selected IDs list, `.setValue(idOrArray)`.

### 3. Events & Callbacks
Define functions globally to handle event hooks:
```javascript
window["onSelectBoxChanged_<ColumnName>"] = function(value, instance, e) {};
window["onTagBoxChanged_<ColumnName>"] = function(value, instance, e) {};
window["onTextSearchSelected_<ColumnName>"] = function(item, instance) {};
```

### 4. Critical Patterns & Synchronization
*   **Suppress Change Trigger**: To programmatically update control values without executing event handlers or triggering AutoSave, wrap with suppress/resume methods:
    ```javascript
    Instance<ColumnName><UID>._suppressValueChangeAction();
    Instance<ColumnName><UID>.option("value", newVal);
    Instance<ColumnName><UID>._resumeValueChangeAction();
    ```
*   **AutoSave Sequence**: Triggered on value change -> validates -> submits `dataJSON` & `idValsJSON` -> triggers `onHpaAutoSaveSuccess` event -> syncs shared grid.
*   **SharedGrid Sync**: Sync a local value update back to the main UI Grid:
    ```javascript
    let key = window.currentClicked_<GridColumnName>;
    window.updateSharedGridRow("<GridColumnName>", { "<KeyUpdateGrid>": key, "<ColumnName>": newValue });
    ```
*   **DataSource Binding Rule**: If a control has a `DataSourceSP`, `loadDataSourceCommon` **MUST** be defined and executed **BEFORE** the control's `loadUI` script:
    ```javascript
    loadDataSourceCommon("<ColumnName>", "<DataSourceSP>", function(data) {});
    ```

### 5. Runtime & Global Environment Variables
*   `window["DataSource_<ColumnName>"]`: Array of bound items.
*   `window["DataSourceIDField_<ColumnName>"]`: Key field (default `"ID"`).
*   `window["DataSourceNameField_<ColumnName>"]`: Display field (default `"Name"`).
*   `window.currentRecordID_<ColumnIDName>`: Holds active editing record ID.
*   `window.currentClicked_<GridColumnName>`: Holds clicked row key in grid.
*   `window["<ColumnName>_SelectedID_<UID>"]`: Tracks autocomplete selection.
*   `window["_hideID_<ColumnName><UID>"]` / `window["_hideSearch_<ColumnName><UID>"]`: UI customization flags (set prior to `loadUI`).

### 6. Code Integrity Rules
*   **DO NOT** manually override standard widget events (e.g. `onValueChanged`) directly; use system-defined global callback patterns instead.
*   **DO NOT** call `loadDataSourceCommon` twice for the same column datasource.
*   **DO NOT** invoke `Instance` variables outside local closures where they are declared.
*   **Escape SQL N-Strings**: When rendering JS inside SQL strings, always double-escape single quotes (`''`) or declare `@SQ NCHAR(1) = CHAR(39)` and concatenate.
