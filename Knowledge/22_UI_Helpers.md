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
