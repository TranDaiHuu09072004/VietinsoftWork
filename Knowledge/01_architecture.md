# 01 — Architecture Reference

## 1. Client Platforms
ParadiseHR supports 3 client groups sharing a single database/business layer:
*   **Windows Desktop**: Default layout (no platform flags). Heavy HR administration, Crystal Reports, local Excel/Access import.
*   **Web Application**: Admin and ESS Portal. `tblDeviceCodeInfo.platform = 'Web'`. Flags: `MEN_Menu.IsWeb`, `ViewOnWeb`, `isShowLayOutWeb`; `tblSC_Login.ActiveWeb`. Main URL: `tblParameter.APPLICATION_ADDRESS = https://paradisehrm.com/Vietinsoft`.
*   **Mobile App (ESS)**: Employee self-service (Android/iOS). `tblDeviceCodeInfo.platform IN ('Android', 'iOS')`. Flags: `MEN_Menu.IsUseMobileDevice`, `isShowInMobileLayOut`, `MobileDeviceGroup`, `ParentMenuMobileID`, `PriorityMobileDevice`.
*   *Note*: `MEN_Menu.NotUsePlatform` supports enum integers representing other variations (mobile-tablet, kiosk, etc.).

## 2. Self-Service (ESS) Configuration
ESS is accessible via Web and Mobile for users flagged with `IsSelfService = 1` and `ActiveWeb = 1` in `tblSC_Login`.
### Key parameters in `tblParameter` for Mobile ESS:
*   `LEFT_MENU_MOBILE`: Menu IDs shown on the left panel.
*   `ALREG_MENU_MOBILE` / `OTREG_MENU_MOBILE` / `MEAL_MENU_MOBILE`: Menu groups for Leave, OT, and Meals.
*   `MOBILE_AUTO_ATT_OPT`: Auto-attendance via Wifi/GPS.
*   `MOBILE_MANUAL_ATT_OPT`: Manual mobile attendance (Photo/GPS).
*   `mobileatt_khoangcachchamcong`, `mobileatt_thoigianchamcong`, `mobileatt_trungkhopkhonmat`, `mobileatt_vitrichinhxac`, `mobileatt_yeucauchamcongwifi`: Rules for GPS distance, time, facial match, accuracy, Wifi SSID constraint.
*   `ThemeWeb` / `ThemeMobile`: Styling themes.

## 3. Platform Field Summary
| Area | Web | Mobile | Desktop |
|---|---|---|---|
| `MEN_Menu` | `IsWeb`, `ViewOnWeb`, `isShowLayOutWeb` | `IsUseMobileDevice`, `isShowInMobileLayOut`, `MobileDeviceGroup` | Default layout |
| `tblDataSetting` | `LayoutDataConfigWeb`, `WebDataGridKeys`, `UseAPIOptionForWeb` | `LayoutDataConfigMobile`, `LayoutMobileLocalConfig`, `ColumnHideMobile` | Default config |
| `tblSC_Login` | `ActiveWeb`, `IsSelfService` | `MobileSizeWidth/Height/Option`, `MobilePhone` | Default admin |
| Procedures | `*_ForUserWeb`, `*_web`, `SC_Login_GetWebInfo` | `MenuMobile`, `*_Mobile`, `get_mobileatt_GPS` | No suffix |
