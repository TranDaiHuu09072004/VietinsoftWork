# LOAD_EMPLOYEE_AVATAR_GUIDE: Global Cache System

Reference: [23_CallAPI.md](23_CallAPI.md) (Client AJAX), [15_employee_query_apis.md](15_employee_query_apis.md) (Employee directory).

To optimize client load times, employee avatars are loaded using a two-step process: render a default inline SVG immediately, then load the binary image asynchronously from the server and cache it.

```
[1] Render SVG Default (Instant) -> [2] Query Memory Cache -> [3] Async Fetch Blob (if paramImg exists) -> [4] Save to window.GlobalEmployeeAvatarCache -> [5] Update img[data-emp-id]
```

---

## 1. Database Ingestion (SQL Server)
Stored procedures must retrieve the encrypted file parameter using `dbo.fn_GetStringParamImageByEmployeeID`:
```sql
SELECT e.EmployeeID AS ID, e.FullName AS Name, e.EmployeeCodeReal AS Code,
       dbo.fn_GetStringParamImageByEmployeeID(e.EmployeeID) AS paramImg,
       'paradisefile_sp_GetFileAPI' AS storeImgName
FROM tblEmployee e WHERE e.IsActive = 1;
```

---

## 2. Global Memory Cache: `GlobalEmployeeAvatarCache`
Registered globally on the window context:
`window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};`
Stores mappings of `EmployeeID` keys to resolved Blob URLs: `{ "EMP001": "blob:http://..." }`.

---

## 3. JavaScript Async Avatar Loader
Include these functions in your page controller script:
```javascript
window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};

// Asynchronously load a single avatar
function loadEmployeeAvatarAsync(empId, employee) {
    return new Promise((resolve) => {
        if (window.GlobalEmployeeAvatarCache[empId]) {
            resolve(window.GlobalEmployeeAvatarCache[empId]);
            return;
        }
        if (!employee?.paramImg) {
            resolve(null);
            return;
        }

        const paramImg = employee.paramImg;
        const storeImgName = employee.storeImgName || "paradisefile_sp_GetFileAPI";

        AjaxHPAParadise({
            data: { name: storeImgName, param: decodeURIComponent(paramImg) },
            xhrFields: { responseType: "blob" },
            cache: true,
            success: function (blob) {
                try {
                    let blobUrl = "";
                    if (blob instanceof Blob) {
                        blobUrl = URL.createObjectURL(blob);
                    } else if (blob instanceof ArrayBuffer) {
                        blobUrl = URL.createObjectURL(new Blob([blob], { type: "image/jpeg" }));
                    } else if (typeof blob === "string" && blob.startsWith("blob:")) {
                        blobUrl = blob;
                    }

                    if (blobUrl) {
                        window.GlobalEmployeeAvatarCache[empId] = blobUrl;
                        $("img[data-emp-id='" + empId + "']").attr("src", blobUrl); // Update DOM matches
                    }
                    resolve(blobUrl || null);
                } catch (ex) {
                    console.warn("Avatar process error: " + empId, ex);
                    resolve(null);
                }
            },
            error: function () { resolve(null); }
        });
    });
}

// Batch load list of avatars
function loadEmployeeAvatarsBatch(employees) {
    if (Array.isArray(employees)) {
        employees.forEach(emp => { if (emp.ID) loadEmployeeAvatarAsync(emp.ID, emp); });
    }
}
```

---

## 4. UI Component Integration Patterns

### 4.1. Inline SVG Placeholder HTML
Render this initial SVG element which will be replaced with an `<img>` tag once the blob is resolved:
```html
<div class="emp-avatar-container" data-emp-id="EMP001">
    <!-- Default SVG icon -->
    <svg viewBox="0 0 24 24" width="70%" height="70%" fill="none" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
    </svg>
</div>
```

### 4.2. DevExtreme DataGrid Cell Template
Use this template configuration inside your grid column definitions:
```javascript
{
    dataField: "EmployeeIDs", // Comma-delimited list of IDs, e.g. "EMP01,EMP02"
    cellTemplate: function(cellElement, cellInfo) {
        if (!cellInfo.value) return;
        const empIds = String(cellInfo.value).split(",").map(id => id.trim()).filter(id => id);
        const employeeList = window["DataSource_EmployeeList"] || [];
        const $container = $("<div>").css({ "display": "flex", "align-items": "center", "gap": "2px" });

        empIds.slice(0, 3).forEach((empId, idx) => {
            const emp = employeeList.find(x => x.ID == empId);
            if (!emp) return;
            const cachedUrl = window.GlobalEmployeeAvatarCache[empId];

            const $img = $("<img>")
                .attr("src", cachedUrl || "/images/default-avatar.png")
                .attr("data-emp-id", empId)
                .css({ "width": "28px", "height": "28px", "border-radius": "50%", "border": "2px solid white", "margin-left": idx > 0 ? "-10px" : "0" });

            $container.append($img);
            if (!cachedUrl) loadEmployeeAvatarAsync(empId, emp);
        });
        $container.appendTo(cellElement);
    }
}
```

### 4.3. Render Avatars Stack
Dynamically renders a list of avatars with a "+X" overflow count badge:
```javascript
function renderAvatarStack(containerId, employees, maxShow = 3) {
    const $container = $("#" + containerId).empty();
    employees.slice(0, maxShow).forEach((emp, idx) => {
        const cachedUrl = window.GlobalEmployeeAvatarCache[emp.ID];
        const $img = $("<img>").attr("data-emp-id", emp.ID).attr("title", emp.Name)
            .attr("src", cachedUrl || "/images/default-avatar.png")
            .css({ "width": "32px", "height": "32px", "border-radius": "50%", "border": "2px solid white", "margin-left": idx > 0 ? "-12px" : "0" });

        $container.append($img);
        if (!cachedUrl && emp.paramImg) loadEmployeeAvatarAsync(emp.ID, emp);
    });

    if (employees.length > maxShow) {
        const $badge = $("<div>").text("+" + (employees.length - maxShow))
            .css({ "width": "32px", "height": "32px", "border-radius": "50%", "background": "#e8e8e8", "display": "flex", "align-items": "center", "justify-content": "center", "font-weight": "bold", "border": "2px solid white", "margin-left": "-12px" });
        $container.append($badge);
    }
}
```

---

## 5. Garbage Collection & Memory Release
Revoke Object URLs on page unload to prevent memory leaks:
```javascript
function clearEmployeeAvatarCache() {
    if (window.GlobalEmployeeAvatarCache) {
        Object.keys(window.GlobalEmployeeAvatarCache).forEach(key => {
            const url = window.GlobalEmployeeAvatarCache[key];
            if (url?.startsWith("blob:")) {
                try { URL.revokeObjectURL(url); } catch (e) {}
            }
        });
        window.GlobalEmployeeAvatarCache = {};
    }
}
```
