# 07 — Hệ thống Menu (Logic tạo + vận hành menu ParadiseHR)

> Tổng quan cấu trúc menu 5 mảnh, quy ước, phân loại, quy trình tạo, cờ phân tách nền tảng, cache HTML và luồng nghiệp vụ.
>
> 💡 **Tạo menu Web mới**? Xem [12_CreateMenu.md](12_CreateMenu.md) (Quy trình 10 phase + ví dụ Hello world + CustomStore).
> 🔁 **Migrate/Update menu**? Xem [13_Migrate_Menu.md](13_Migrate_Menu.md) (Quy trình inventory + scan dependency + script idempotent).
> 🎨 **Giao diện/Style**? Xem [14_ParadiseStyle.md](14_ParadiseStyle.md).
> 🔍 **Tìm procedure từ tên menu**? Xem [18_FindMenuProcedure.md](18_FindMenuProcedure.md).

---

## 1. Cấu trúc menu — 5 mảnh liên kết qua `MenuID`

| # | Bảng | Vai trò |
|---|---|---|
| 1 | `MEN_Menu` | Định nghĩa menu: PK = `MenuID`, vị trí, class, cờ nền tảng |
| 2 | `tblSC_Object` | Đối tượng phân quyền: `Description = MenuID`, `ObjectName = '<Assembly>.<Class>'` |
| 3 | `tblMD_Message` | Tên đa ngôn ngữ: `MessageID = MenuID`, `Language = 'VN'/'EN'/...` |
| 4 | `tblDataSetting` | Cấu hình grid + proc CRUD (chỉ với `AssemblyName = 'DataSetting'`) |
| 5 | `tblSC_Right_Stored` / `tblSC_GroupRight` | Cấp quyền sử dụng (xem [11_permissions.md](11_permissions.md)) |

*Bảng liên quan*: `tblWorkFlow` (quy trình), `Menu_FrameSetting` (SuperForm), `tblContextMenu` (menu chuột phải).

---

## 2. Quy ước đặt tên

- **`MenuID`**: `Mnu<MODULE><N>` (Ví dụ: `MnuHRS142`). `MODULE` (3 ký tự): `HRS` (nhân sự), `TAD` (chấm công), `PRL` (lương), `MDT` (master data), `WPT` (portal), `SCR` (hệ thống)...
- **`ObjectName`** trong `tblSC_Object`: `<AssemblyName>.<ClassName>` (Ví dụ: `DataSetting.vtblEmployeeList`). Bắt buộc đúng format để hệ thống kiểm tra quyền.

---

## 3. Phân loại theo `AssemblyName`

| AssemblyName | Loại | Yêu cầu cấu hình |
|---|---|---|
| `DataSetting` | Grid tự động dựng từ view/table/proc | 1 dòng trong `tblDataSetting` (`TableName`, `ProcSelect`, `KeyColumn`, `IsList`, `FormType`...) |
| `SuperForm` | Form đa tab/section | Config trong `Menu_FrameSetting` |
| `HPA.<Module>` | Form Winform viết tay | `ClassName` = tên class C# trong code app |

---

## 4. Ví dụ: Menu "Danh sách nhân viên" (`MnuHRS142`)

- `MEN_Menu`: `MenuID='MnuHRS142'`, `ClassName='vtblEmployeeList'`, `AssemblyName='DataSetting'`, `ParentMenuID='MnuHRS000'`, `IsVisible=1`, `GroupID='MnuHRS0000'`
- `tblSC_Object`: `ObjectName='DataSetting.vtblEmployeeList'`, `Description='MnuHRS142'`, `Visible=1`
- `tblMD_Message`: `MessageID='MnuHRS142'`, `Language='VN'`, `Content=N'Danh sách nhân viên'`
- Nguồn dữ liệu: `vtblEmployeeList` (SQL View)

---

## 5. Quy trình tạo menu thủ công (Tóm tắt)

1. **Tạo nguồn dữ liệu** (View/Procedure).
2. **Chọn `MenuID`**: `MAX` trong nhóm + 1. (⚠️ **BẮT BUỘC** query kiểm tra tính khả dụng trong `MEN_Menu`, `tblMD_Message`, `tblSC_Object` trước khi chốt số, tuyệt đối không dùng ID đã có trong DB dù không hiện trên UI. Xem Rule 0 ở file `12_CreateMenu.md`).
3. **Thêm `MEN_Menu`**:
   ```sql
   INSERT INTO MEN_Menu (MenuID, ClassName, AssemblyName, ParentMenuID, Priority, IsVisible, glyphicon, GroupID, IsWeb, IsUseMobileDevice)
   VALUES ('MnuHRSXXX', 'vtblEmployeeList', 'DataSetting', 'MnuHRS000', 2, 1, 'UserList', 'MnuHRS0000', 0, 0);
   ```
4. **Thêm `tblSC_Object`**:
   ```sql
   INSERT INTO tblSC_Object (ObjectID, ObjectName, Description, Visible, ParentObjectID)
   VALUES ((SELECT MAX(ObjectID)+1 FROM tblSC_Object), 'DataSetting.vtblEmployeeList', 'MnuHRSXXX', 1, (SELECT ObjectID FROM tblSC_Object WHERE Description = 'MnuHRS000'));
   ```
5. **Thêm tên ngôn ngữ**:
   ```sql
   EXEC dbo.[1rename_Mess] 'MnuHRSXXX', 'VN', N'Danh sách nhân viên';
   EXEC dbo.[1rename_Mess] 'MnuHRSXXX', 'EN', 'Employee List';
   ```
6. **Cấp quyền**:
   ```sql
   INSERT INTO tblSC_Right_Stored (LoginID, ObjectID, FullAccess) VALUES (@LoginID, @ObjID, 32);
   ```

---

## 6. Lệnh tạo nhanh `sp_s_CreateMenu`

Tự động thực hiện các bước tạo dữ liệu menu, ngôn ngữ và gán quyền direct:
```sql
EXEC dbo.sp_s_CreateMenu
     @Text         = N'Danh sách nhân viên',
     @TextEN       = 'Employee List',
     @ClassName    = 'vtblEmployeeList',
     @ParentMenuID = 'MnuHRS000',
     @AssemblyName = 'DataSetting',
     @Option       = 1,                  -- 0: in script preview, 1: thực thi
     @LoginIDList  = '1,3,5';            -- Danh sách LoginID nhận quyền FullAccess (32)
```

---

## 7. Các cờ cấu hình và hai cơ chế render HTML

### Các cờ trên `MEN_Menu`
* **Nền tảng**: `IsWeb`, `ViewOnWeb`, `isShowLayOutWeb` (Web); `IsUseMobileDevice`, `isShowInMobileLayOut` (Mobile).
* **Hiển thị**: `IsVisible` (phải bằng 1), `isParentMenu`, `isLeftMenu` (1 = ẩn khỏi menubar), `isHiddenInTree`.
* **Parent Menu**: Phải có `IsVisible = 1` (Tránh `MnuHEP000` vì mặc định bị ẩn).

### 2 cơ chế hiển thị menu HTML-rendered
1. **WebView qua Mobile Engine (Legacy)**:
   * **Cấu hình cờ**: `IsWeb=0`, `ViewOnWeb=0`, `IsUseMobileDevice=1`, `isShowInMobileLayOut=0`.
   * **Yêu cầu**: Cấu hình đủ 3 bảng:
     - `tblDataSetting`: 1 dòng (`TableName = <ClassName>`, `IsProcedure=1`, `IsShowLayout=1`, `ColumnDataType='html&ViewHtml'`, `ColumnOrderBy='html&0'`).
     - `tblDataSettingLayout`: 2 dòng (`root` container + item `lblhtml` trỏ tới `ControlType='ParadiseWebView2'`).
     - `tblHtmlScriptCache`: HTML/CSS/JS cache.
   * **Ví dụ**: `MnuKPI007`, `MnuTM022`, `MnuWPT037`.
2. **Pure HTML Render (Hiện đại - KHUYẾN NGHỊ)**:
   * **Cấu hình cờ**: `IsWeb=1`, `isShowLayOutWeb=1`, `IsUseMobileDevice=0`, `isShowInMobileLayOut=0`.
   * **Yêu cầu**: Chỉ cần cache HTML trong `tblHtmlScriptCache`. Bỏ qua cấu hình `tblDataSetting` và `tblDataSettingLayout`. Hệ thống tự động chạy ClassName (procedure wrapper) và lấy kết quả cột `html` để render thẳng.
   * **Ví dụ**: `MnuAT009`, `MnuSCR605`, `MnuSCR010`.

---

## 8. Giao diện Desktop vs Web lưu ở đâu

### Desktop App
Mặc định khi `IsWeb=0` và `IsUseMobileDevice=0`. Layout dữ liệu grid lưu tại `tblDataSetting` (các cột default). Cấu hình form lưu ở `Menu_FrameSetting`.
```sql
SELECT m.MenuID, msg.Content AS MenuNameVN, m.ClassName, o.ObjectName, ds.TableName
FROM MEN_Menu m
LEFT JOIN tblMD_Message msg ON msg.MessageID = m.MenuID AND msg.Language = 'VN'
LEFT JOIN tblSC_Object o    ON o.Description = m.MenuID
LEFT JOIN tblDataSetting ds ON ds.TableName = m.ClassName
WHERE m.IsVisible = 1 AND m.IsWeb = 0 AND m.IsUseMobileDevice = 0;
```

### Web Portal
Khi cờ `IsWeb=1` hoặc `IsUseMobileDevice=1`. Giao diện dạng grid động config bằng `tblDataSetting` (`LayoutDataConfigWeb`) kết hợp với `tblCommonControlType_Signed` (metadata cho từng column/control). Giao diện tự do (HTML-rendered) lấy từ `tblHtmlScriptCache.html`.

---

## 9. Web layout kiểu mới bằng HTML cache

Áp dụng cho các màn hình custom hoàn toàn (Ví dụ: **Xếp hạng nhân viên** `MnuTM022` và **Chi tiết xếp hạng** `MnuTM025`).

### Quy trình hoạt động
1. User click menu `MnuTM022` $\rightarrow$ App gọi wrapper SP `sp_Train_Ranking_Template`.
2. SP wrapper trả về cột `html` lấy từ bảng `tblHtmlScriptCache` ứng với renderer SP `sp_Train_Ranking_Template_html`.
3. Client load HTML lên WebView (`ParadiseWebView2`), JavaScript trong HTML chạy và gọi API động qua `AjaxHPAParadise` để lấy data từ SP `sp_Rank_getPersonalRating`.

### Cấu trúc bảng cache `tblHtmlScriptCache`
Cần đảm bảo đầy đủ các cột khi insert:
`TableName` (PK), `LanguageID` (PK - 'VN'/'EN'), `ScreenType` (mặc định '-1'), `html`, `HtmlParadise`, `paradiseJs`, `Version`, `VersionData`.

---

## 10. Nghiệp vụ Tính điểm XP và Xếp hạng nhân viên

Màn hình xếp hạng (`MnuTM022`) gọi API `sp_Rank_getPersonalRating`, bên trong chạy `sp_PerformanceKPI_Working_Process` để tính điểm XP và lưu vào `tblRank_PersonalRating_Detail`.

### Danh mục loại điểm (`tblRank_PointType`)
* `1`: Hoàn thành bài học.
* `2`: Hoàn thành tốt công việc (Task có `StatusID = 4` trong `tblTask_Tasks`, điểm = `StandardTime * 2`).
* `3`: Thưởng.
* `4`: Khác.
* `5`: Đi trễ (phút trễ * `-2`).
* `6`: Về sớm (phút về sớm * `-2`).
* `7`: Vào sớm (phút vào sớm * `0.5`, không tính khi miss GPS).
* `8`: Về trễ (phút về trễ * `0.5`, không tính khi miss GPS).
* `9`: Giờ công (phút làm việc * `1`, tối đa 480 phút/ngày. Đi công tác `CT`/làm việc ở nhà `WFH` cộng theo `LvAmount * 60`).
* `10`: Làm việc cuối tuần (số phút * `1`, tối thiểu làm 30 phút).

### Thuật toán xếp hạng
```sql
SELECT EmployeeID, SUM(ExperiencePoints) AS TotalPoints, SUM(Coin) AS TotalCoin, MIN(CreatedDate) AS EarliestDate
FROM tblRank_PersonalRating_Detail
WHERE CreatedDate BETWEEN @FilterDateFrom AND @FilterDateTo
GROUP BY EmployeeID;

-- Xếp hạng theo: TotalPoints giảm dần -> EarliestDate tăng dần -> FullName tăng dần (ROW_NUMBER)
```

---

## 11. Refresh cache và quyền hạn
Sau khi thay đổi menu, **chỉ gọi duy nhất lệnh này** để làm sạch cache:
```sql
EXEC dbo.sp_Men_Menu_AfterSave_Simple @ClassName = N'<ClassName>';
```
⚠️ **TUYỆT ĐỐI KHÔNG** dùng `EXEC sp_UpdateMenuInUserRight` trong script tự động vì proc này tự cấp quyền cho toàn bộ tài khoản trong hệ thống (`LoginID > 0`), vi phạm nghiêm ngặt quy tắc phân quyền (Rule 1).

---

## 12. Menu phê duyệt tăng ca (Đang hoạt động)

1. **Desktop**: `MnuTAD060` - *Xác nhận dữ liệu tăng ca* (`ClassName = 'TA_OverTime_List_Approval'`).
2. **Web Portal**: `MnuWPT037` - *Danh sách phê duyệt* (`ClassName = 'sp_List_To_Review'` $\rightarrow$ gọi `sp_overtime_assignment` để duyệt tăng ca nhóm 6).
3. ❌ **Lỗi thời (Deprecated)**: `MnuATTAppOT` (`/ATT/ApprovalOTList.aspx`).
