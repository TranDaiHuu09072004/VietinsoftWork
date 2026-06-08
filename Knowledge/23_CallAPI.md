# 23 — JavaScript Client API Calling Reference

Reference: [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) (Script safety), [22_UI_Helpers.md](22_UI_Helpers.md) (Error alerts).

Use the global async helper `AjaxHPAParadise` to execute SQL Server Stored Procedures from JavaScript client scripts.

## 0. Mandatory Pre-Code Rule for `AjaxHPAParadise`

> **RULE #1:** When writing (vibe) code that calls `AjaxHPAParadise` with a stored procedure `name: "sp_X"`, the Agent **MUST** verify the procedure exists in the database first.

**Process:**

1. **Check DB first**: `SELECT OBJECT_ID('dbo.sp_X') AS ProcExists`
2. **If not found (`ProcExists IS NULL`)**: MUST ask the user:
   > *"Procedure `sp_X` does not exist in the DB. Do you want me to create and handle it?"*
3. **Only create after user agrees** — never auto-create procedures.
4. **If exists**: verify source via `OBJECT_DEFINITION(OBJECT_ID('dbo.sp_X'))` to ensure parameters match the client call.

**Why mandatory:** Prevents HTTP 500 runtime errors when a menu runs but the procedure does not exist, and ensures every procedure is created intentionally and reviewed by the user.

---

## 1. Standard API Calling Template
```javascript
AjaxHPAParadise({
    data: {
        name: "sp_ProcedureName",
        param: [
            "LoginID", window.UserID || window.LoginID,
            "LanguageID", window.LanguageID || "VN",
            "FilterKey1", val1,
            "FilterKey2", val2
        ]
    },
    success: function (res) {
        try {
            // Decrypt payload if encrypted
            if (typeof res === "string" && res.trim() !== "") {
                res = res.includes("{") ? res : EncryptionStringDecryption(res);
            }
            const json = typeof res === "string" ? JSON.parse(res) : res;
            
            // Extract result-sets
            const mainData = json?.data?.[0] || [];  -- Select 1 (Main rows)
            const extraData = json?.data?.[1] || []; -- Select 2 (e.g. TotalCount)
            
            // Perform operations with data...
        } catch (e) {
            console.error("API response parsing error:", e);
        }
    },
    error: function (err) {
        if (window.uiManager?.showAlert) {
            window.uiManager.showAlert({ type: "error", message: "Failed to load data from server." });
        }
    }
});
```

---

## 2. Four Rules for Parameters (`param`)
1.  **Flat Array Format**: Always pass parameters as a linear array of key-value pairs: `["Key1", val1, "Key2", val2]`. Do **not** send an object `{Key1: val1}`.
2.  **No `@` Prefix**: Write parameter keys as clean text (e.g. `"LoginID"`, not `"@LoginID"`). The backend binder appends the prefix.
3.  **Mandatory System Context**: Always pass `"LoginID"` (`window.UserID || window.LoginID`) and `"LanguageID"` (`window.LanguageID || "VN"`).
4.  **Dynamic Assembly**: Instantiate an empty array `let params = [...]` and run `params.push("Key", val)` dynamically based on filters.

---

## 3. Response Structure (`json.data`)
Every `SELECT` statement in the procedure maps to an index in the returned `data` array:
*   `json.data[0]`: First `SELECT` output (records).
*   `json.data[1]`: Second `SELECT` output (usually `TotalCount` for grids).
*   `json.data[2]`: Third `SELECT` output (usually metrics summaries).

---

## 4. Binary File / Image Ingestion
To load binary documents or profile images from the database, call `paradisefile_sp_GetFileAPI` and configure the request as a binary blob:
```javascript
AjaxHPAParadise({
    data: {
        name: "paradisefile_sp_GetFileAPI",
        param: [ "LoginID", window.UserID || window.LoginID, "FileID", fileId, "TableName", "tblEmployee" ]
    },
    xhrFields: { responseType: "blob" }, // Prerequisite: Request raw binary blob
    success: function (blob) {
        if (blob) {
            $("#employeeAvatar").attr("src", URL.createObjectURL(blob));
        }
    }
});
```

---

## 5. Pagination Wrappers vs Direct Actions
*   **Grid Lists with Pagination**: To load DevExtreme grid views that require paging, search, filtering, and summaries, pass the business SP through the paging wrapper `sp_LoadGridUsingAPI` (which expects parameters like `Take`, `Skip`, `SearchValue`, `Filters`).
*   **Detail Views**: When retrieving a single detail card by ID, call the SP directly via `AjaxHPAParadise` (e.g., `name: "sp_GetRecordDetail"`). Pass the primary key directly; do not use the pagination wrapper.

---

## 6. Common Issues Checklist
*   *HTTP 500 error*: Check if `param` was passed as an object instead of a flat array.
*   *Empty data*: Check if payload requires decrypting via `EncryptionStringDecryption(res)`, or check if `LoginID`/`LanguageID` are missing.
*   *JS runtime errors*: Ensure scripts execute inside page load handlers after system helpers are loaded.

---

## 7. List SP vs Detail SP — Mandatory Separation

> **MANDATORY:** Every menu with both a list grid and a detail form must have **2 separate SPs**. NEVER reuse the same SP for both list and detail.

| SP Type | Purpose | Called via | Required Parameters |
|---|---|---|---|
| **List SP** (`sp_X_List`) | Lightweight grid data | `sp_LoadGridUsingAPI` → `@ProcName` | `@TempTableAPIName`, `@Skip`, `@Take`, `@SearchValue` |
| **Detail SP** (`sp_X_Detail`) | Full detail form | `AjaxHPAParadise` directly | Primary key (e.g. `@TemplateName`) |

**List SP requirements:**
- Only columns needed for grid display (no heavy `NVARCHAR(MAX)` columns)
- `SELECT ... INTO @TempTableAPIName` — `sp_LoadGridUsingAPI` auto-reads & formats response
- Pagination via `OFFSET/FETCH NEXT` based on `@Skip`/`@Take`

**Detail SP returns:**
- All columns needed by the form (including `Body NVARCHAR(MAX)`, config columns, etc.)
- Direct `SELECT`, no `INTO` temp table
