# richtext: Rich Text Editor Base64 Encoding & Decoding

Reference: [20_ControlSystem.md](20_ControlSystem.md) (Control properties), [23_CallAPI.md](23_CallAPI.md) (API communications).

The control `hpaControlRichTextEditorPremium` requires HTML contents to be encoded in Base64 UTF-16LE format when stored in the database, and decoded upon loading.

---

## 1. SQL Server decoding (Base64 UTF-16LE to NVARCHAR)
Extracts Base64 string raw bytes to VARBINARY and casts back to NVARCHAR:
```sql
DECLARE @ActualHTML NVARCHAR(MAX);
BEGIN TRY
    IF @Data IS NULL OR @Data = ''
        SET @ActualHTML = N'';
    ELSE IF @Data LIKE 'PHNjcmlwdA%' OR @Data LIKE '<%'  -- HTML or script fallback
        SET @ActualHTML = @Data;
    ELSE
        -- Convert Base64 string -> VARBINARY (UTF-16LE bytes) -> NVARCHAR
        SET @ActualHTML = CAST(CAST(N'' AS XML).value('xs:base64Binary(sql:variable("@Data"))', 'VARBINARY(MAX)') AS NVARCHAR(MAX));
END TRY
BEGIN CATCH
    SET @ActualHTML = @Data; -- Fail-safe fallback
END CATCH
```

---

## 2. JavaScript encoding (String to Base64 UTF-16LE)
Converts standard JS strings to UTF-16 Little Endian byte buffers, and encodes to Base64:
```javascript
function utf16_le_to_b64_<ColumnName><UID>(str) {
    var buf = new ArrayBuffer(str.length * 2);
    var view = new Uint8Array(buf);
    for (var i = 0; i < str.length; i++) {
        var code = str.charCodeAt(i);
        view[i * 2]     = code & 0xFF;         // Low byte (little-endian)
        view[i * 2 + 1] = (code >> 8) & 0xFF;  // High byte
    }
    var binary = '';
    for (var j = 0; j < view.length; j++) {
        binary += String.fromCharCode(view[j]);
    }
    return btoa(binary);
}
```

---

## 3. Integration Patterns

### 3.1. Manual Saving Mode (`_autoSave = false`)
Used when `AutoSave = 0` (or `_autoSave<ColumnName><UID> = false`). Execute custom extraction:
```javascript
let html = Instance<ColName><UID>.getHtml();
let b64 = utf16_le_to_b64_<ColName><UID>(html);

AjaxHPAParadise({
    data: { name: "sp_SaveContent", param: ["LoginID", LoginID, "HTMLContent", b64] }
});
```

### 3.2. Automated AutoSave Mode (`_autoSave = true`)
Toggle the flag **before** executing `loadUI`. The framework automatically intercept changes, encodes the buffer, and submits the update.
```javascript
window["_autoSave_<ColumnName><UID>"] = true;
// Followed by standard: select loadUI and select loadData calls.
```

---

## 4. Client-Side API References
*   `Instance<ColName><UID>.getHtml()`: Fetches current editor text as raw HTML.
*   `Instance<ColName><UID>.setHtml(html)`: Binds a raw HTML string into the editor.
*   `Instance<ColName><UID>.value`: Directly reads/updates the unformatted text value.
*   `rteObj_<ColName><UID>`: Direct reference to the raw editor premium instance.
