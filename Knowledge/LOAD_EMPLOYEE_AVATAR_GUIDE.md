# Hướng Dẫn Load Avatar Nhân Viên - Global Cache System

## 0. Luồng Tối Ưu: SVG Default → Blob Async Load

### Nguyên lý
- **Khởi động nhanh**: Render SVG mặc định (không fetch server)
- **Lazy loading**: Nếu `paramImg` tồn tại → Async load blob từ server
- **Cache bộ nhớ**: Lần thứ 2 dùng cache, không gọi server lại

### Sơ đồ luồng
```
┌─────────────────────────────────┐
│ HTML Render (SVG Default)       │  ← Nhanh, không fetch
├─────────────────────────────────┤
│ Kiểm tra cache                  │  ← Nếu có → xài ngay
├─────────────────────────────────┤
│ Nếu paramImg → Load async       │  ← Gọi server lấy blob
├─────────────────────────────────┤
│ Blob received → createObjectURL │  ← Tạo blob URL
├─────────────────────────────────┤
│ Cache blob URL                  │  ← Lưu vào memory
├─────────────────────────────────┤
│ Update img[data-emp-id]         │  ← Replace SVG → Blob image
└─────────────────────────────────┘
```

### HTML Mặc Định (SVG Avatar)
```html
<div class="approver-avatar-wrapper">
    <!-- SVG default - hiển thị ngay, không fetch -->
    <svg viewBox="0 0 24 24" width="70%" height="70%" fill="none" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
    </svg>
</div>
```

### Sau khi Load Thành Công (Blob Image)
```html
<div class="approver-avatar-wrapper">
    <!-- IMG blob - thay thế SVG khi load xong -->
    <img src="blob:http://..." style="width: 100%; height: 100%; border-radius: 50%; object-fit: cover;" />
</div>
```

---

## 1. Cấu Trúc Cache Toàn Cục

```javascript
// Khởi tạo cache
window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};

// Cache structure:
// {
//   "empID_1": "blob:http://...",
//   "empID_2": "blob:http://...",
//   ...
// }
```

---

## 2. SQL Stored Procedure - Trả Về Dữ Liệu Avatar

### Cấu trúc kết quả trả về từ procedure:

```sql
SELECT 
    e.EmployeeID AS ID,
    e.FullName AS Name,
    e.Code,
    dbo.fn_GetStringParamImageByEmployeeID(e.EmployeeID) AS paramImg,
    e.DepartmentID,
    -- ... các trường khác
FROM tblEmployee e
WHERE e.IsActive = 1
```

### Ví dụ Stored Procedure:

```sql
CREATE PROCEDURE sp_GetEmployeeList
    @DepartmentID INT = NULL,
    @LanguageID VARCHAR(10) = 'VN'
AS
BEGIN
    SELECT 
        e.EmployeeID AS ID,
        e.FullName AS Name,
        e.Code,
        dbo.fn_GetStringParamImageByEmployeeID(e.EmployeeID) AS paramImg,
        'paradisefile_sp_GetFileAPI' AS storeImgName  -- Store procedure để load avatar
    FROM tblEmployee e
    WHERE (@DepartmentID IS NULL OR e.DepartmentID = @DepartmentID)
        AND e.IsActive = 1
    ORDER BY e.FullName
END
```

---

## 3. Hàm JavaScript Load Avatar Async

### DEFAULT_AVATAR_SVG - Biến Global Sẵn Có

```javascript
// DEFAULT_AVATAR_SVG đã được định nghĩa global trong web
// Ví dụ: window.DEFAULT_AVATAR_SVG hoặc DEFAULT_AVATAR_SVG
// Giả sử web đã có sẵn thẻ SVG:
// <svg viewBox="0 0 24 24" width="70%" height="70%" fill="none" stroke="currentColor" stroke-width="1.5">
//     <path stroke-linecap="round" stroke-linejoin="round" d="M15.75 6a3.75 3.75 0 11-7.5 0 3.75 3.75 0 017.5 0zM4.501 20.118a7.5 7.5 0 0114.998 0A17.933 17.933 0 0112 21.75c-2.676 0-5.216-.584-7.499-1.632z" />
// </svg>

// Khởi tạo cache
window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};
```

### Hàm tiện ích: Load Avatar từ Server (Async)

```javascript
/**
 * Load avatar cho 1 nhân viên từ server
 * @param {string} empId - ID nhân viên
 * @param {object} employee - Object nhân viên chứa paramImg và storeImgName
 * @returns {Promise<string>} Blob URL hoặc null
 */
function loadEmployeeAvatarAsync(empId, employee) {
    return new Promise((resolve) => {
        // Kiểm tra cache trước
        if (window.GlobalEmployeeAvatarCache && window.GlobalEmployeeAvatarCache[empId]) {
            resolve(window.GlobalEmployeeAvatarCache[empId]);
            return;
        }

        if (!employee || !employee.paramImg) {
            resolve(null);
            return;
        }

        const paramImg = employee.paramImg;
        const storeImgName = employee.storeImgName || "paradisefile_sp_GetFileAPI";

        AjaxHPAParadise({
            data: {
                name: storeImgName,
                param: decodeURIComponent(paramImg)
            },
            xhrFields: { responseType: "blob" },
            cache: true,
            success: function (blob) {
                try {
                    let blobUrl = "";
                    
                    if (blob instanceof Blob) {
                        blobUrl = URL.createObjectURL(blob);
                    } else if (blob instanceof ArrayBuffer) {
                        const newBlob = new Blob([blob], { type: "image/jpeg" });
                        blobUrl = URL.createObjectURL(newBlob);
                    } else if (typeof blob === "string" && blob.startsWith("blob:")) {
                        blobUrl = blob;
                    }

                    if (blobUrl) {
                        // Lưu vào cache
                        window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};
                        window.GlobalEmployeeAvatarCache[empId] = blobUrl;

                        // Cập nhật tất cả img tag với data-emp-id tương ứng
                        $("img[data-emp-id='" + empId + "']").attr("src", blobUrl);
                    }
                    
                    resolve(blobUrl || null);
                } catch (ex) {
                    console.warn("Error processing avatar blob for " + empId, ex);
                    resolve(null);
                }
            },
            error: function (err) {
                console.warn("Failed to load avatar for " + empId, err);
                resolve(null);
            }
        });
    });
}

/**
 * Load avatar batch cho danh sách nhân viên
 * @param {array} employees - Mảng object nhân viên có {ID, Name, paramImg, storeImgName}
 */
function loadEmployeeAvatarsBatch(employees) {
    if (!Array.isArray(employees) || employees.length === 0) return;

    employees.forEach(emp => {
        if (emp.ID) {
            loadEmployeeAvatarAsync(emp.ID, emp);
        }
    });
}
```

---

## 4. Cách Sử Dụng Trong Các Tình Huống Khác Nhau

### A. Avatar Đơn (1 ảnh)

```javascript
// HTML
<div class="employee-card">
    <img class="avatar" data-emp-id="EMP001" src="/images/default-avatar.png" />
    <span class="emp-name">Nguyễn Văn A</span>
</div>

// JavaScript - Load và render
function renderEmployeeCard(employee) {
    const empId = employee.ID;
    const $card = $(".employee-card");
    
    // Set tên
    $card.find(".emp-name").text(employee.Name);
    
    // Set avatar mặc định
    $card.find(".avatar")
        .attr("data-emp-id", empId)
        .attr("title", employee.Name);
    
    // Load async
    loadEmployeeAvatarAsync(empId, employee).then(url => {
        if (url) {
            $card.find(".avatar").attr("src", url);
        }
    });
}
```

### B. Avatar Stack (Nhiều ảnh xếp lớp)

```html
<!-- HTML -->
<div class="avatar-stack" id="employee-avatars">
    <!-- Render động bằng JS -->
</div>

<style>
    .avatar-stack {
        display: flex;
        align-items: center;
        position: relative;
    }
    
    .avatar-stack img {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        border: 2px solid white;
        margin-left: -12px;
        cursor: pointer;
        box-shadow: 0 0 4px rgba(0,0,0,0.1);
        flex-shrink: 0;
    }
    
    .avatar-stack img:first-child {
        margin-left: 0;
    }
    
    .avatar-count {
        width: 32px;
        height: 32px;
        border-radius: 50%;
        background: #e8e8e8;
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 12px;
        font-weight: bold;
        border: 2px solid white;
        margin-left: -12px;
        cursor: default;
    }
</style>

<script>
/**
 * Render avatar stack
 * @param {array} employees - Mảng nhân viên
 * @param {number} maxVisible - Số avatar tối đa hiển thị (default: 3)
 */
function renderAvatarStack(employees, maxVisible = 3) {
    const $container = $("#employee-avatars");
    $container.empty();
    
    if (!Array.isArray(employees) || employees.length === 0) {
        return;
    }
    
    const showCountBadge = employees.length > maxVisible;
    const visibleCount = showCountBadge ? maxVisible - 1 : maxVisible;
    
    // Render avatars
    employees.slice(0, visibleCount).forEach((emp, index) => {
        const $img = $("<img>")
            .attr("src", "/images/default-avatar.png")
            .attr("title", emp.Name)
            .attr("data-emp-id", emp.ID)
            .css({
                "z-index": employees.length - index
            });
        
        $container.append($img);
        
        // Load async
        loadEmployeeAvatarAsync(emp.ID, emp);
    });
    
    // Render "+X" badge
    if (showCountBadge) {
        const remaining = employees.length - visibleCount;
        const $badge = $("<div>")
            .addClass("avatar-count")
            .attr("title", "+" + remaining + " more")
            .text("+" + remaining);
        
        $container.append($badge);
    }
}

// Cách sử dụng
renderAvatarStack(employeeList, 3);
</script>
```

### C. Trong DataGrid Cell (DevExtreme)

```javascript
// Đã được implement sẵn trong complaint_form.html
// Code này cho các grid khác:

{
    dataField: "EmployeeIDs",  // Giả sử là chuỗi "ID1,ID2,ID3"
    caption: "Nhân viên",
    cellTemplate: function(cellElement, cellInfo) {
        const val = cellInfo.value;
        if (!val) return;
        
        const empIds = String(val).split(",").map(id => id.trim()).filter(id => id);
        const ds = window["DataSource_EmployeeList"] || [];
        
        const $container = $("<div>").css({
            "display": "flex",
            "align-items": "center",
            "gap": "2px"
        });
        
        empIds.slice(0, 3).forEach((empId, idx) => {
            const emp = ds.find(x => x.ID == empId);
            if (!emp) return;
            
            const cachedUrl = window.GlobalEmployeeAvatarCache[empId];
            
            const $img = $("<img>")
                .attr("src", cachedUrl || "/images/default-avatar.png")
                .attr("title", emp.Name)
                .attr("data-emp-id", empId)
                .css({
                    "width": "28px",
                    "height": "28px",
                    "border-radius": "50%",
                    "border": "2px solid white",
                    "margin-left": idx > 0 ? "-10px" : "0"
                });
            
            $container.append($img);
            
            // Load async
            if (!cachedUrl) {
                loadEmployeeAvatarAsync(empId, emp);
            }
        });
        
        $container.appendTo(cellElement);
    }
}
```

### D. Trong Form/Modal

```html
<!-- HTML -->
<div class="form-group">
    <label>Người phê duyệt</label>
    <div class="approver-info">
        <img class="approver-avatar" src="/images/default-avatar.png" />
        <div class="approver-details">
            <div class="approver-name"></div>
            <div class="approver-code"></div>
        </div>
    </div>
</div>

<script>
function displayApproverInfo(approver) {
    const $avatar = $(".approver-avatar");
    const $name = $(".approver-name");
    const $code = $(".approver-code");
    
    // Set thông tin
    $avatar.attr("title", approver.Name).attr("data-emp-id", approver.ID);
    $name.text(approver.Name || "-");
    $code.text(approver.Code || "-");
    
    // Load avatar
    loadEmployeeAvatarAsync(approver.ID, approver).then(url => {
        if (url) {
            $avatar.attr("src", url);
        }
    });
}
</script>
```

---

## 5. Tối Ưu Cache Cleanup

```javascript
/**
 * Clear cache khi không cần nữa
 * (Giải phóng bộ nhớ)
 */
function clearEmployeeAvatarCache() {
    if (window.GlobalEmployeeAvatarCache) {
        Object.keys(window.GlobalEmployeeAvatarCache).forEach(key => {
            const url = window.GlobalEmployeeAvatarCache[key];
            if (url && url.startsWith("blob:")) {
                try {
                    URL.revokeObjectURL(url);
                } catch (e) {}
            }
        });
        window.GlobalEmployeeAvatarCache = {};
    }
}

/**
 * Clear cache cho 1 nhân viên cụ thể
 */
function clearEmployeeAvatarCacheByID(empId) {
    if (window.GlobalEmployeeAvatarCache && window.GlobalEmployeeAvatarCache[empId]) {
        const url = window.GlobalEmployeeAvatarCache[empId];
        if (url && url.startsWith("blob:")) {
            try {
                URL.revokeObjectURL(url);
            } catch (e) {}
        }
        delete window.GlobalEmployeeAvatarCache[empId];
    }
}

// Gọi khi đóng form/modal
// clearEmployeeAvatarCache();
```

---

## 6. Pattern: SVG Default → Blob Async Load

### Ý tưởng chính
1. **Render SVG default** - hiển thị ngay không cần server
2. **Nếu có paramImg** - async load blob từ server
3. **Update khi sẵn sàng** - thay SVG bằng blob image

### Ví dụ 1: Avatar trong Approval Flow

```javascript
function renderApprovers(stages) {
    const container = document.getElementById("approval-flow-container");
    container.innerHTML = "";

    stages.forEach((stage, idx) => {
        const node = document.createElement("div");
        node.className = "approver-node";

        // 1. Render SVG default immediately (fast)
        // Sử dụng DEFAULT_AVATAR_SVG global đã được định nghĩa sẵn
        const cachedUrl = window.GlobalEmployeeAvatarCache?.[stage.ApproverID];
        
        if (cachedUrl) {
            // Nếu đã có cache → dùng blob image
            node.innerHTML = `
                <div class="approver-avatar-wrapper">
                    <img src="${cachedUrl}" style="width: 100%; border-radius: 50%; object-fit: cover;" />
                </div>
                <div>${stage.ApproverName}</div>
            `;
        } else {
            // Nếu chưa → render SVG default (biến global)
            node.innerHTML = `
                <div class="approver-avatar-wrapper">
                    ${window.DEFAULT_AVATAR_SVG || DEFAULT_AVATAR_SVG}
                </div>
                <div>${stage.ApproverName}</div>
            `;
        }

        container.appendChild(node);

        // 2. Nếu có paramImg → async load blob
        if (!cachedUrl && stage.paramImg) {
            loadEmployeeAvatarAsync(stage.ApproverID, stage).then(blobUrl => {
                // 3. Khi blob load xong → update avatar-wrapper
                if (blobUrl) {
                    const wrapper = node.querySelector(".approver-avatar-wrapper");
                    if (wrapper) {
                        wrapper.innerHTML = `
                            <img src="${blobUrl}" style="width: 100%; border-radius: 50%; object-fit: cover;" />
                        `;
                    }
                }
            });
        }
    });
}
```

### Ví dụ 2: Avatar trong Card (Đơn giản hơn)

```html
<!-- HTML: SVG default hoặc placeholder image -->
<div class="employee-card">
    <div class="card-avatar">
        <!-- Dùng DEFAULT_AVATAR_SVG global hoặc placeholder image -->
        <!-- Option 1: Inline SVG (từ DEFAULT_AVATAR_SVG) -->
        <!-- Option 2: <img src="/images/default-avatar.png" /> -->
    </div>
    <div class="card-name"><!-- tên --> </div>
</div>

<script>
function renderEmployeeCard(employee) {
    const $card = $(".employee-card");
    const $avatar = $card.find(".card-avatar");
    const $name = $card.find(".card-name");

    // Set tên
    $name.text(employee.Name);

    // Check cache
    const cachedUrl = window.GlobalEmployeeAvatarCache?.[employee.ID];
    if (cachedUrl) {
        // Đã có cache → render blob image
        $avatar.html(`<img src="${cachedUrl}" style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%;" />`);
    } else {
        // Render SVG default từ biến global
        $avatar.html(window.DEFAULT_AVATAR_SVG || DEFAULT_AVATAR_SVG || '<img src="/images/default-avatar.png" style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%;" />');

        // Async load blob nếu có paramImg
        if (employee.paramImg) {
            loadEmployeeAvatarAsync(employee.ID, employee).then(blobUrl => {
                if (blobUrl) {
                    $avatar.html(`<img src="${blobUrl}" style="width: 100%; height: 100%; object-fit: cover; border-radius: 50%;" />`);
                }
            });
        }
    }
}
</script>
```

### Ví dụ 3: Avatar Stack (Nhiều ảnh)

```javascript
function renderAvatarStack(employees, maxShow = 3) {
    const $container = $("#avatar-stack");
    $container.empty();

    employees.slice(0, maxShow).forEach((emp, idx) => {
        const cachedUrl = window.GlobalEmployeeAvatarCache?.[emp.ID];
        
        // Render img với SVG fallback
        const $img = $("<img>")
            .attr("title", emp.Name)
            .attr("data-emp-id", emp.ID)
            .css({
                "width": "32px",
                "height": "32px",
                "border-radius": "50%",
                "border": "2px solid white",
                "margin-left": idx > 0 ? "-12px" : "0"
            });

        if (cachedUrl) {
            // Đã có cache → load ngay
            $img.attr("src", cachedUrl);
        } else {
            // Render SVG default hoặc placeholder
            // Có thể dùng: /images/default-avatar.png hoặc
            // Inline SVG (nếu muốn dùng DEFAULT_AVATAR_SVG global)
            $img.attr("src", "/images/default-avatar.png");

            // Async load blob nếu có paramImg
            if (emp.paramImg) {
                loadEmployeeAvatarAsync(emp.ID, emp);
            }
        }

        $container.append($img);
    });

    // Render +X badge
    if (employees.length > maxShow) {
        $container.append(
            $("<div>")
                .text("+" + (employees.length - maxShow))
                .css({
                    "width": "32px",
                    "height": "32px",
                    "border-radius": "50%",
                    "background": "#e8e8e8",
                    "display": "flex",
                    "align-items": "center",
                    "justify-content": "center",
                    "font-weight": "bold",
                    "border": "2px solid white",
                    "margin-left": "-12px"
                })
        );
    }
}
```

### Hiệu suất so sánh

| Phương pháp | Load time | Memory | Network |
|-----------|-----------|--------|---------|
| **SVG Default** | Ngay lập tức | Thấp | 0 |
| **SVG → Blob Lazy** | Nhanh + async | Trung bình | Khi cần |
| **Blob Only** | Chậm (block render) | Cao | Luôn |

---

## 7. Checklist Implement

- [ ] **SQL Procedure trả về:**
  - `ID` (EmployeeID)
  - `Name` (FullName)
  - `Code` (Employee Code)
  - `paramImg` (từ `dbo.fn_GetStringParamImageByEmployeeID()`)
  - `storeImgName` (='sp_GetEmployeeAvatar')

- [ ] **JavaScript setup:**
  - `window.GlobalEmployeeAvatarCache = {}`
  - Hàm `loadEmployeeAvatarAsync(empId, employee)`
  - Hàm `loadEmployeeAvatarsBatch(employees)`

- [ ] **HTML/Template:**
  - Thêm `data-emp-id="..."` vào img tag
  - Thêm `title="..."` để hiện tên khi hover

- [ ] **Render:**
  - Gọi `loadEmployeeAvatarAsync()` hoặc `loadEmployeeAvatarsBatch()`
  - Tự động cập nhật img src khi blob load xong

---

## 8. Ví Dụ Toàn Bộ (Dùng Luôn)

```javascript
// ===== KHỞI TẠO =====
window.GlobalEmployeeAvatarCache = window.GlobalEmployeeAvatarCache || {};

// ===== LOAD DANH SÁCH NHÂN VIÊN =====
function loadAndRenderEmployeeList() {
    AjaxHPAParadise({
        data: {
            name: "sp_GetEmployeeList",
            param: ["DepartmentID", null, "LanguageID", "VN"]
        },
        success: function(res) {
            const json = typeof res === "string" ? JSON.parse(res) : res;
            const employees = (json.data && json.data[0]) || [];
            
            // Load all avatars batch
            loadEmployeeAvatarsBatch(employees);
            
            // Render UI
            renderEmployeeList(employees);
        }
    });
}

function renderEmployeeList(employees) {
    const $container = $("#employee-list");
    $container.empty();
    
    employees.forEach(emp => {
        const $card = $("<div>").addClass("employee-card");
        
        const $avatar = $("<img>")
            .addClass("avatar")
            .attr("src", "/images/default-avatar.png")
            .attr("data-emp-id", emp.ID)
            .attr("title", emp.Name);
        
        const $info = $("<div>").addClass("info")
            .append($("<div>").text(emp.Name))
            .append($("<div>").text(emp.Code));
        
        $card.append($avatar).append($info);
        $container.append($card);
    });
}

// ===== GỌI KHI CẦN =====
loadAndRenderEmployeeList();
```

---

## 8. Notes

✅ **Lợi ích:**
- Cache toàn cục → không load lại nếu đã có
- Async → không block UI
- Batch load → hiệu năng tốt
- Reusable cho bất kỳ component nào

⚠️ **Chú ý:**
- `paramImg` từ SQL phải decode được
- `sp_GetEmployeeAvatar` phải trả về Blob hoặc ảnh
- Kiểm tra `data-emp-id` trong img tag để cập nhật
- Cleanup cache khi form đóng để tránh memory leak
