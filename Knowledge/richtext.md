# Rich Text Editor (hpaControlRichTextEditorPremium) — Encode/Decode Base64

> Dùng khi làm việc với control `hpaControlRichTextEditorPremium`: lưu HTML vào DB (encode Base64 UTF-16LE) và đọc ngược lại (decode). File này bổ trợ cho [20_ControlSystem.md](20_ControlSystem.md).

## 1. Luồng dữ liệu

```
┌─ User nhập HTML (tiếng Việt, ảnh, định dạng) trong editor
├─ JS: utf16_le_to_b64_<ColName><UID>(html) → Base64 UTF-16LE
├─ SQL: lưu chuỗi Base64 vào cột NVARCHAR
├─ SQL: decode Base64 → CAST về NVARCHAR → hiển thị
└─ JS: Instance<ColName><UID>.getHtml() → lấy HTML hiện tại
```

## 2. SQL — Decode Base64 UTF-16LE

```sql
DECLARE @ActualHTML NVARCHAR(MAX);

BEGIN TRY
    IF @Data IS NULL OR @Data = ''
        SET @ActualHTML = N'';
    ELSE IF @Data LIKE 'PHNjcmlwdA%' OR @Data LIKE '<%'  -- HTML thô hoặc script
        SET @ActualHTML = @Data;
    ELSE
        -- XML convert Base64 → VARBINARY (byte UTF-16LE) → CAST sang NVARCHAR
        SET @ActualHTML = CAST(
            CAST(N'' AS XML).value('xs:base64Binary(sql:variable("@Data"))', 'VARBINARY(MAX)')
            AS NVARCHAR(MAX)
        );
END TRY
BEGIN CATCH
    -- Fallback: nếu decode lỗi thì dùng raw
    SET @ActualHTML = @Data;
END CATCH
```

> **Nguyên lý:** Client gửi Base64 của UTF-16LE. `xs:base64Binary` trả về `VARBINARY` (chính là byte UTF-16LE). `CAST(VARBINARY AS NVARCHAR)` hiển thị đúng tiếng Việt.

## 3. JavaScript — Encode Base64 UTF-16LE

```javascript
function utf16_le_to_b64_<ColumnName><UID>(str) {
    // B1: Chuyển chuỗi JavaScript (UTF-16) thành mảng byte UTF-16LE
    var buf = new ArrayBuffer(str.length * 2);
    var view = new Uint8Array(buf);
    for (var i = 0; i < str.length; i++) {
        var code = str.charCodeAt(i);
        view[i * 2]     = code & 0xFF;         // byte thấp (little-endian)
        view[i * 2 + 1] = (code >> 8) & 0xFF;  // byte cao
    }

    // B2: ArrayBuffer → Base64
    var binary = '';
    var bytes = new Uint8Array(buf);
    for (var j = 0; j < bytes.length; j++) {
        binary += String.fromCharCode(bytes[j]);
    }
    return btoa(binary);
}
```

## 4. Hai trường hợp sử dụng

### TH1 — `_autoSave = false` (mặc định, xử lý thủ công)

Khi control có `AutoSave = 0` (mặc định trong `tblCommonControlType_Signed`), hoặc `_autoSave<ColumnName><UID> = false`. Renderer tự gọi `getHtml()` và encode rồi gửi API thủ công:

```javascript
// Lấy HTML từ editor
var html = Instance<ColName><UID>.getHtml();

// Encode Base64 UTF-16LE
var b64 = utf16_le_to_b64_<ColName><UID>(html);

// Gửi lên server thủ công
AjaxHPAParadise({
    data: {
        name: "sp_MySaveProc",
        param: ["LoginID", LoginID, "Content", b64]
    }
});
```

### TH2 — AutoSave

Chỉ cần set `_autoSave<ColumnName><UID> = true` trước khi loadUI. Hệ thống tự động:
1. Gọi `Instance<ColName><UID>.getHtml()` để lấy HTML
2. Gọi `utf16_le_to_b64_<ColName><UID>(html)` để encode
3. Gửi Base64 lên server qua `AjaxHPAParadise`
4. SQL SP decode Base64 → lưu NVARCHAR

```javascript
// Set TRƯỚC khi inject loadUI
_autoSave<ColumnName><UID> = true;

// Load UI + Load Data — dùng select loadUI và select loadData như bình thường
+(select loadUI from tblCommonControlType_Signed where UID = '<UID>')
+(select loadData from tblCommonControlType_Signed where UID = '<UID>')
```

> **Load giao diện & load data:** Luôn dùng `select loadUI` và `select loadData` từ `tblCommonControlType_Signed` — không cần code tay.

## 5. JS API

| Hàm | Mô tả |
|-----|-------|
| `Instance<ColName><UID>.getHtml()` | Lấy nội dung HTML hiện tại từ editor |
| `Instance<ColName><UID>.setHtml(html)` | Gán HTML vào editor |
| `Instance<ColName><UID>.value` | Get/set value (raw) |
| `rteObj_<ColName><UID>` | Object editor gốc (Premium) |
| `utf16_le_to_b64_<ColName><UID>(str)` | Encode chuỗi JS → Base64 UTF-16LE |
| `_autoSave<ColumnName><UID> = true` | Bật AutoSave (đặt trước loadUI) |

## 6. Lưu ý

- `hpaControlRichTextEditor` (không Premium) đã **không còn sử dụng** ([20_ControlSystem.md §A.2](20_ControlSystem.md))
- Ảnh trong HTML được xử lý qua `data-original-url` → `convertPathToBlobUrl()` → `blob:http://...`
- Khi đọc từ DB ra hiển thị: dùng decode SQL (section 2), gán vào `setHtml()`
