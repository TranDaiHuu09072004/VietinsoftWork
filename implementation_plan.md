# Kế hoạch triển khai (Đã cập nhật theo Database Paradise_ITL)

Dạ em xin lỗi vì lúc nãy em đứng ở database Dev nên không thấy các bảng. Em đã query vào `Paradise_ITL` và xác nhận tất cả các cột `Level`, `DedicatedTrainerID`, `TeamLeaderID` và bảng `tblTrainingStatusHistory` đều **đã có sẵn**! Dưới đây là kế hoạch chi tiết hoàn chỉnh:

## 1. Thông tin hồ sơ (Profile Info)
### 1.1 Trạng thái đào tạo & Level
- **Lấy dữ liệu**: Em sẽ tạo thủ tục `sp_TAD_EmployeeScheduleDetail_GetTrainingStatus` gọi trực tiếp vào bảng `tblTrainingStatus` để lấy `TrainingStatusID` và `TrainingStatusName`.
- **Giao diện & Auto Save**:
  - Dùng `dxSelectBox` cho Trạng thái đào tạo. Mặc định gán bằng giá trị cột `Level` của Nhân viên (vì `Level` tương đương với `StatusID`).
  - Ô "Level" hiển thị kế bên cũng lấy từ cột `Level`.
  - Viết sự kiện `onValueChanged`: Khi user đổi trạng thái, Javascript sẽ gọi API `sp_TAD_EmployeeScheduleDetail_UpdateTrainingStatus` để:
    1. Update cột `Level` trong bảng `tblEmployee`.
    2. Insert một dòng log vào bảng `tblTrainingStatusHistory`.
    3. Update ngay ô hiển thị Level trên màn hình.

### 1.2 Hiển thị Người đào tạo & Quản lý
- **Lấy dữ liệu**: Trong thủ tục `sp_TAD_EmployeeScheduleDetail_GetEmpInfo`, em sẽ `LEFT JOIN` thêm với chính bảng `tblEmployee` để lấy ra **Họ tên** của `DedicatedTrainerID` và `TeamLeaderID`.
- **Giao diện**: Thêm 2 field vào HTML Thông tin hồ sơ. Nếu nhân viên có dữ liệu, sẽ hiển thị Tên người đào tạo / Quản lý. Nếu Null, Javascript sẽ tự động ẩn (`display: none`).
- **PIC Chấm công**: Giữ fix cứng chữ "Team Leader" theo đúng yêu cầu Task.

## 2. Lịch sử trạng thái Training (Timeline)
- Tạo thủ tục `sp_TAD_EmployeeScheduleDetail_GetTrainingHistory` truy vấn từ bảng `tblTrainingStatusHistory`.
- `INNER JOIN` với `tblTrainingStatus` để lấy `StatusName` của từng lịch sử.
- Đổ dữ liệu lên giao diện Timeline thành 1 hàng ngang, gồm: `ChangedDate` (Ngày) - `StatusName` (Trạng thái) - `Remarks` (Ghi chú).

## 3. Lịch làm việc phân ca (Tab Lịch làm việc & Popup sửa)
- **Phương án Control UI**: Theo quyết định của anh qua form khảo sát ban nãy, em sẽ **tiếp tục sử dụng DevExtreme JS thuần** (dxSelectBox, dxDateBox, dxTextBox) để tránh lỗi crash màn hình ngầm do `tblCommonControlType_Signed` của framework gây ra.
- **Data Ca làm việc**: Sẽ gọi API để load `WorkStart`, `WorkEnd` từ bảng `tblShiftSetting` đổ vào SelectBox. Em sẽ tạo sẵn dữ liệu mẫu (`INSERT`) cho lịch làm việc để anh test.

## 4. Chứng chỉ / Kỹ năng
- Thay vì lấy bảng chứng chỉ riêng, em sẽ sử dụng chính dữ liệu từ bảng `tblTrainingStatus` theo yêu cầu của task.
- Tạo thủ tục `sp_TAD_EmployeeScheduleDetail_GetCertificates` trả về `StatusName` và `StatusNameEN` (hoặc mô tả) từ `tblTrainingStatus`. Loại bỏ "Ngày hiệu lực" và "% đạt" trên giao diện.

---
> [!TIP]
> **Kết luận**: Mọi vướng mắc về Database đã được giải quyết. Kế hoạch đã hoàn thiện và tuân thủ 100% nội dung `Task_huu.docx` và các tuỳ chọn anh đã duyệt. 
> 
> **Xin anh duyệt Plan để em bắt tay vào viết Script ngay lập tức ạ!**
