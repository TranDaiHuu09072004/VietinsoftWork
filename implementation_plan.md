# Plan Hoàn Thiện Tạo Lịch Tự Động Và Popup Phân Ca Đào Tạo

## 1. Mục Tiêu Chốt

- Hoàn thiện nút `Tạo lịch tự động` trong popup `Chi tiết nhân sự & phân ca`.
- Nhân viên nằm trong danh sách `Phân ca đào tạo` mặc định hiển thị `FBT Training` là trạng thái đào tạo đầu tiên.
- Bỏ popup/cảnh báo đang bị lẫn với thao tác đổi sang ca khác.
- Chỉ giữ popup xác nhận khi xếp ca `Hành Chính` vượt số ngày chuẩn của trạng thái đào tạo.
- Auto-schedule phải xử lý được trường hợp xếp cả tuần vượt quota, không chỉ khi người dùng đổi ca thủ công.
- Nút `Xóa ca` trong popup sửa ca cần CSS rõ ràng hơn, nhìn giống hành động nguy hiểm nhưng không phá layout.
- Không xóa bảng dữ liệu khác, không sửa schema, không sửa quyền menu.

## 2. Quyết Định Nghiệp Vụ

- `FBT Training` là trạng thái đào tạo khởi đầu cho toàn bộ nhân viên trong danh sách phân ca đào tạo.
- `Level` giữ nguyên theo dữ liệu hiện có; nếu null thì vẫn hiển thị placeholder `-- Chưa có Level nào --`.
- Không cấm chọn `Day`, `Mid`, `Night` trong giai đoạn đào tạo.
- Không hiển thị popup hỏi khi đổi từ `Hành Chính` sang ca khác nữa, vì popup hiện tại đang gây hiểu nhầm.
- Popup chỉ dùng cho một việc duy nhất: xác nhận xếp vượt quota ca `Hành Chính`.
- Nếu logic popup quota vẫn bị lẫn hoặc không kiểm soát được trong UI hiện tại, phương án fallback là bỏ hẳn popup confirm quota và chỉ hiển thị warning sau khi lưu. Tuy nhiên hướng ưu tiên là sửa popup quota cho đúng.

## 3. Quota Ca Hành Chính

- `FBT Training`: chuẩn 4 ngày `Hành Chính`.
- `SHTP` + `Level 1` hoặc level null/khác 1-2: chuẩn 1 ngày `Hành Chính`.
- `SHTP` + `Level 2`: chuẩn 2 ngày `Hành Chính`.
- Quota chỉ áp dụng khi ca được xếp là `Hành Chính`.
- `Day`, `Mid`, `Night` không bị quota này chặn hoặc hỏi confirm.
- Khi vượt quota:
  - Hiện popup: `Nhân viên đã được xếp quá số ngày Hành Chính chuẩn của FBT Training. Anh có muốn tiếp tục xếp thêm không?`
  - Chọn `Có`: vẫn lưu/tạo lịch.
  - Chọn `Hủy`: không lưu/tạo lịch.

## 4. Thay Đổi SQL Trong Script

- Thêm hoặc hoàn thiện `sp_TAD_EmployeeScheduleDetail_AutoSchedule`.
- Procedure nhận các tham số tối thiểu:
  - `@LoginID`
  - `@LanguageID`
  - `@EmployeeID`
  - `@FilterType`
  - `@Force BIT = 0`
- Nếu nhân viên chưa có trạng thái đào tạo hoặc đang hiển thị từ danh sách phân ca đào tạo, procedure mặc định dùng `FBT Training`.
- Nếu chưa có ngày bắt đầu FBT trong `tblTrainingStatusHistory`, lấy ngày đầu của khoảng lịch đang xem làm ngày bắt đầu.
- Auto-schedule tìm ca `Hành Chính` đúng `WeekDays` từ `tblShiftSetting`.
- Auto-schedule chỉ insert vào ngày đang trống trong `tblWSchedule`, không ghi đè lịch đã có.
- Khi `@Force = 0` và số ngày `Hành Chính` sẽ vượt quota:
  - Không insert.
  - Trả `NeedConfirm = 1`, `Message`, `PlannedRows`, `QuotaLimit`, `CurrentHCDays`.
- Khi `@Force = 1`:
  - Insert các ngày còn trống dù vượt quota.
  - Trả `NeedConfirm = 0`, `InsertedRows`.

- Sửa `sp_TAD_EmployeeScheduleDetail_CheckTrainingQuota`:
  - Chỉ kiểm tra quota khi ca chọn là `Hành Chính`.
  - Không còn đoạn hỏi confirm khi chọn ca khác `Hành Chính`.
  - Trả shape ổn định: `NeedConfirm`, `Message`, `ConfirmType`.
  - `ConfirmType = 'QuotaExceeded'` khi vượt quota.

- Sửa `sp_TAD_EmployeeScheduleDetail_SaveSchedule`:
  - Không hard-error quota FBT/SHTP.
  - Không chặn ca khác `Hành Chính`.
  - Vẫn validate `ShiftID` tồn tại và đúng `WeekDays`.
  - Vẫn insert/update `tblWSchedule`.
  - Vẫn tránh nhân bản `tblTrainingStatusHistory` cùng `EmployeeID + ChangedDate + StatusID`.

- Sửa `sp_TAD_EmployeeScheduleDetail_GetEmpInfo`:
  - Trả thêm field để UI biết nhân viên có thuộc danh sách phân ca đào tạo hay không.
  - Nếu thuộc danh sách này thì `TrainingStatusDisplay`/select mặc định là `FBT Training`.
  - Không bắt buộc update DB ngay khi mở form; chỉ ghi DB khi user lưu profile, lưu ca, hoặc chạy auto-schedule.

## 5. Thay Đổi UI/JS

- Thêm nút `Tạo lịch tự động` cạnh cụm `Tuần này` / `Tháng này`.
- Khi bấm:
  - Hiện confirm lần đầu: `Anh có muốn tự động tạo lịch Hành Chính cho giai đoạn đào tạo hiện tại không?`
  - Nếu đồng ý, gọi `sp_TAD_EmployeeScheduleDetail_AutoSchedule` với `@Force = 0`.
  - Nếu API trả `NeedConfirm = 1`, hiện popup quota.
  - Nếu user chọn `Có`, gọi lại API với `@Force = 1`.
  - Sau khi tạo xong, refresh calendar.

- Popup sửa/chọn ca:
  - Bỏ popup hỏi khi chọn ca khác `Hành Chính`.
  - Khi lưu ca `Hành Chính`, gọi `sp_TAD_EmployeeScheduleDetail_CheckTrainingQuota`.
  - Nếu `NeedConfirm = 1`, hiện popup quota; chọn `Có` thì mới gọi save.
  - Nếu `NeedConfirm = 0`, save trực tiếp.

- Dropdown trạng thái đào tạo:
  - Nhân viên trong danh sách phân ca đào tạo mặc định chọn `FBT Training`.
  - Không tự động ghi DB chỉ vì mở form.
  - Nếu người dùng đổi trạng thái thủ công thì autosave như hiện tại.

- Calendar:
  - Hiển thị text nhỏ trạng thái đào tạo bên cạnh ngày làm việc.
  - Không còn chữ `Khuyến nghị` trên ca `Hành Chính`.
  - Ca `Hành Chính` vẫn có thể nổi bật bằng màu/viền nhẹ, nhưng không thêm label gây nhiễu.

- Nút `Xóa ca`:
  - Đặt bên trái footer popup.
  - Style danger nhẹ: viền đỏ, chữ đỏ, hover nền đỏ nhạt, không quá chói.
  - Chỉ hiện khi ngày đang có `ShiftID`.
  - Click mở confirm: `Anh có muốn xóa ca hiện tại không?`
  - Chọn xóa thì gọi `sp_TAD_EmployeeScheduleDetail_DeleteSchedule`, refresh lại ngày về `Chưa phân ca`.

## 6. Kiểm Thử Bắt Buộc

- Nhân viên trong danh sách phân ca đào tạo nhưng `TrainingStatus` null:
  - Mở form hiển thị mặc định `FBT Training`.
  - `Level` vẫn giữ đúng giá trị hiện có hoặc placeholder nếu null.

- Auto-schedule FBT:
  - Lịch trống cả tuần, bấm `Tạo lịch tự động`.
  - Tạo 4 ngày `Hành Chính` đầu tiên theo đúng `WeekDays`.
  - Không ghi đè ngày đã có ca khác.

- Auto-schedule vượt quota:
  - Nhân viên FBT đã có 4 ngày `Hành Chính`.
  - Bấm tạo lịch tiếp hoặc tạo cả tuần khiến vượt 4 ngày.
  - Phải hiện popup hỏi vượt quota.
  - Chọn `Hủy`: không thêm lịch.
  - Chọn `Có`: vẫn thêm lịch.

- Lưu thủ công:
  - Chọn `Day/Mid/Night` trong FBT/SHTP: lưu thẳng, không popup.
  - Chọn `Hành Chính` vượt quota: popup hỏi.
  - Chọn `Có`: lưu.
  - Chọn `Hủy`: không lưu.

- Xóa ca:
  - Ngày có ca mở popup thấy nút `Xóa ca`.
  - Chọn xóa, confirm xong calendar trở về `Chưa phân ca`.
  - Ngày chưa có ca không hiện nút `Xóa ca`.

## 7. Không Làm

- Không xóa `tblAtt_ModuleDetail`.
- Không seed lịch sử trạng thái training đại trà.
- Không gọi `sp_UpdateMenuInUserRight`.
- Không ghi `tblSC_Right_Stored`.
- Không alter `tblWSchedule`.
- Không sửa procedure/menu gốc `Phân ca đào tạo` nếu chưa cần; form chi tiết chỉ tái sử dụng nguồn ca và logic tương thích.

## 8. Ghi Chú Triển Khai

- `implementation_plan_Taolichtudong` dùng chữ `SHTB`; trong script/UI hiện tại đang dùng `SHTP`, nên triển khai theo `SHTP`.
- Nếu cần xác định chính xác “danh sách phân ca đào tạo”, ưu tiên dùng cùng nguồn dữ liệu với menu `Phân ca đào tạo` để tránh lệch danh sách.
- Popup confirm dùng helper global `showConfirmPopup`; nếu môi trường không có helper thì fallback `window.confirm`.
