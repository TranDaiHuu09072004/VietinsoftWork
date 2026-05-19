# 01 — Architecture (3 nền tảng + ESS)

> Cấu trúc client của ParadiseHR. Liên quan: [07_menu_system.md](07_menu_system.md) (cờ menu theo nền tảng), [06_db_login_account.md](06_db_login_account.md) (cờ user theo nền tảng).

## 1. Nền tảng giao diện (Client platforms)

ParadiseHR phục vụ **3 nhóm client** chạy chung một database / business layer:

| Nền tảng | Mục đích | Định danh trong DB |
|---|---|---|
| **Windows Desktop** | Client đầy đủ cho HR/admin (mạnh ở quản trị, in Crystal Report, import file Access/Excel local) | Không có cờ riêng trong `MEN_Menu` — là layout mặc định khi không bật `IsWeb` / `IsUseMobileDevice` |
| **Web application** | Truy cập qua trình duyệt, dùng cho cả admin và nhân viên (ESS portal). URL chính: `tblParameter.APPLICATION_ADDRESS = https://paradisehrm.com/Vietinsoft` | `tblDeviceCodeInfo.platform = 'Web'`; cờ `MEN_Menu.IsWeb`, `ViewOnWeb`, `isShowLayOutWeb`; cờ user `tblSC_Login.ActiveWeb` |
| **Mobile app** (ESS) | App cho nhân viên: chấm công GPS/Wifi, đăng ký nghỉ phép/OT, xem thông báo, suất ăn… Mobile **chia 2 platform riêng**: **Android** và **iOS** | `tblDeviceCodeInfo.platform IN ('Android', 'iOS')`; cờ `MEN_Menu.IsUseMobileDevice`, `isShowInMobileLayOut`, `MobileDeviceGroup`, `ParentMenuMobileID`, `PriorityMobileDevice` |

> Lưu ý: `MEN_Menu.NotUsePlatform` có nhiều giá trị enum số (0,1,2,3,7,8,9,20,21,22) — hệ thống nhận diện nhiều hơn 3 platform ở mức enum code (gồm các biến thể như mobile-tablet, kiosk…). Định nghĩa enum nằm trong code app, không có bảng tra trong DB.

## 2. Self-Service (ESS) — không chỉ trên Mobile

ESS dùng được trên **cả Web lẫn Mobile**, phân biệt qua cờ user ở `tblSC_Login`:

- `IsSelfService = 1` — tài khoản ESS (nhân viên thường, quyền hạn chế).
- `ActiveWeb = 1` — cho phép vào Web (Self-Service Portal).
- `MobileSizeWidth` / `MobileSizeHeight` / `MobileSizeOption`, `MobilePhone` — cấu hình hiển thị Mobile của user.

Các parameter quan trọng (trong `tblParameter`) cho cấu hình ESS Mobile:

| Code | Ý nghĩa |
|---|---|
| `LEFT_MENU_MOBILE` | Danh sách menu ID hiển thị trên thanh trái mobile |
| `ALREG_MENU_MOBILE` | Nhóm menu "Đăng ký nghỉ phép" |
| `OTREG_MENU_MOBILE` | Nhóm menu "Đăng ký tăng ca" |
| `MEAL_MENU_MOBILE` | Nhóm menu "Đăng ký suất ăn" |
| `MOBILE_AUTO_ATT_OPT` | Bật tự động chấm công qua Wifi/GPS |
| `MOBILE_MANUAL_ATT_OPT` | Tuỳ chọn chấm công thủ công bằng điện thoại (chụp ảnh / GPS) |
| `mobileatt_khoangcachchamcong`, `mobileatt_thoigianchamcong`, `mobileatt_trungkhopkhonmat`, `mobileatt_vitrichinhxac`, `mobileatt_yeucauchamcongwifi` | Tham số chi tiết chấm công mobile |
| `OPTION_SHOW_HOMEPAGE_MOBILE`, `GRIDCONTROL_OPTION_MOBILE`, `UIMobileOption`, `ThemeMobile`, `MobileDateBoxOption` | Giao diện mobile |
| `ThemeWeb` | Theme cho Web |

## 3. Cờ tách 3 nền tảng (tóm tắt)

| Đối tượng | Web | Mobile | Desktop |
|---|---|---|---|
| `MEN_Menu` | `IsWeb`, `ViewOnWeb`, `isShowLayOutWeb` | `IsUseMobileDevice`, `isShowInMobileLayOut`, `MobileDeviceGroup` | (mặc định, không cờ riêng) |
| `tblDataSetting` (layout grid) | `LayoutDataConfigWeb`, `WebDataGridKeys`, `UseAPIOptionForWeb` | `LayoutDataConfigMobile`, `LayoutMobileLocalConfig`, `ColumnHideMobile` | Layout default (cùng bảng) |
| `tblSC_Login` (user) | `ActiveWeb`, `IsSelfService` | `MobileSizeWidth/Height/Option`, `MobilePhone` | (mặc định khi `IsSelfService = 0`) |
| Procedure naming | `*_ForUserWeb`, `*_web`, `SC_Login_GetWebInfo` | `MenuMobile`, `*_Mobile`, `get_mobileatt_GPS` | Tên procedure không có suffix nền tảng |
