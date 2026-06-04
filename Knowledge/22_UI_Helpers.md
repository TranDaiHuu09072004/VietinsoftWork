# 22 — Global UI Helpers Reference

Reference: [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md) (Script integration), [14_ParadiseStyle.md](14_ParadiseStyle.md) (Visuals).

Use these global JavaScript UI helpers to display notifications or prompt for confirmation dialogs.

## 1. Toast Notification Alerts (`uiManager.showAlert`)
Displays standard toast notifications.
```javascript
uiManager.showAlert({
    type: "success", // Options: "success" (green), "warning" (yellow), "error" / "danger" (red)
    message: "Action completed successfully."
});
```

## 2. Confirmation Popup Dialogs (`showConfirmPopup`)
Triggers a modal dialog to confirm actions that cannot be undone. Always wrap with a safety type-check to prevent runtime errors on legacy runtimes.
```javascript
if (typeof showConfirmPopup === "function") {
    showConfirmPopup({
        title: "Delete Record?",
        message: "Are you sure you want to permanently delete this item?",
        YesText: "Delete",
        NoText: "Cancel",
        onYes: () => {
            // Delete action callback
        },
        onNo: () => {
            // Cancel/Close callback
        }
    });
}
```

> [!WARNING]
> Luôn bọc ngoài cuộc gọi bằng kiểm tra điều kiện `typeof showConfirmPopup === "function"` để tránh gặp lỗi runtime JS trên các môi trường hoặc nền tảng cũ chưa cập nhật thư viện này.

---

## 3. Hàm chuẩn `normalize(v)` — Loại bỏ dấu tiếng Việt (ParadiseJS Standard)

> **Đây là standard library function của Paradise.** Mọi màn hình cần tìm kiếm/lọc tiếng Việt không dấu đều dùng hàm này.

### Source code (copy-paste vào mọi màn hình)

```js
/**
 * Loại bỏ dấu tiếng Việt, chuyển về chữ thường ASCII.
 * Tương đương fn_RemoveToneMark trong SQL.
 * @param {string} v - Chuỗi đầu vào
 * @returns {string} Chuỗi không dấu, lowercase
 */
const normalize = v => {
    var s = String(v || "").toLowerCase();
    // Fast-path: nếu đã thuần ASCII (0x20-0x7E) thì return ngay
    if (!/[^\x20-\x7E]/.test(s)) return s;
    var r = "";
    for (var i = 0; i < s.length; i++) {
        var c = s.charAt(i), d = c.normalize("NFD");
        r += d.length > 1 ? d.charAt(0) : c;
    }
    return r.replace(/\u0111/g, "d");
};
```

### Cách dùng

```js
// Search không dấu
var q = normalize(keyword);
data.forEach(item => {
    if (normalize(item.name).indexOf(q) >= 0) { /* match */ }
});

// Render data-text cho tree/grid search
var dataText = normalize(rawName); // "Quản trị Nhân sự" → "quan tri nhan su"
```

### Logic (so với SQL `fn_RemoveToneMark`)

| SQL | JS |
|-----|-----|
| `NOT LIKE N'%[^ -~]%' COLLATE Latin1_General_100_BIN2` | `!/[^\x20-\x7E]/.test(s)` |
| NFD decomposition | `c.normalize("NFD")` + `.charAt(0)` |
| `REPLACE(@InputStr, N'đ', N'd')` | `.replace(/\u0111/g, "d")` |
| `REPLACE(@InputStr, N'Đ', N'D')` | (đã `.toLowerCase()` trước) |

### Use cases

- **Tree filter/search**: `data-text="${normalize(name)}"`
- **Grid search**: normalize cả keyword và cell value trước khi `indexOf`
- **Auto-complete/suggestion**: normalize trước khi compare
- **Dashboard cross-filter**: normalize để match label không phân biệt dấu

