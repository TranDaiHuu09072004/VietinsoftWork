# Quy trình Tính Lương (Payroll Calculation Process)

Tài liệu này mô tả chi tiết quy trình tính lương gồm 13 bước, được trích xuất từ cấu hình file Excel tính lương (`Tinh luong.xlsx`). Quy trình được minh họa kèm theo **số liệu thực tế** của một nhân viên mẫu (VD: `VTS0001`) để bạn có bức tranh tổng thể và chính xác nhất.

---

## 1. Thông tin nhân viên (Employee Information)
Dữ liệu cơ bản định danh nhân viên:
*   **Mã nhân viên** (`EmployeeID`) và **Tên nhân viên** (`FullName`). *(Ví dụ: `VTS0001`)*
*   **Phòng ban / Bộ phận / Chức vụ** (`DepartmentName`, `SectionName`, `PositionName`).
*   **Ngày vào làm** (`HireDate`) và **Ngày nghỉ việc** (`TerminateDate` - dùng để chốt công cho người nghỉ ngang).

## 2. Thông tin mức lương & Phụ cấp cố định (Salary Info)
Dữ liệu đầu vào theo hợp đồng hoặc thỏa thuận (Được lưu trữ lịch sử thay đổi mức lương tại bảng `tblSalaryHistory` - ví dụ nhân viên VTS0001 tăng lương từ 10tr lên 12tr):
*   **Lương cơ bản (LCB)**: Đóng vai trò là cột lõi trong tính toán.
    *   👉 **Ví dụ:** `10.000.000 VNĐ`
*   **Phụ cấp (PC)** bao gồm:
    *   *PC Điện thoại*: **Miễn thuế**. 👉 **Ví dụ:** `300.000 VNĐ`
    *   *PC Trách nhiệm*: **Tính thuế**. 👉 **Ví dụ:** `500.000 VNĐ`
    *   *PC Cơm*: Tính theo ngày đi làm (25k/ngày), **miễn thuế tối đa 730k/tháng**. 👉 **Ví dụ tổng nhận:** `1.300.000 VNĐ` (trong đó 570k bị tính thuế, 730k miễn thuế).

## 3. Dữ liệu công (Attendance Information)
*   **Công chuẩn**: Số ngày công tiêu chuẩn của tháng. 👉 **Ví dụ:** `27 ngày`
*   **Công chính**: Số ngày làm việc thực tế. 👉 **Ví dụ:** `26 ngày`
*   **Nghỉ phép hưởng lương**: 👉 **Ví dụ:** `1 ngày`
*   **Số giờ tăng ca**: 
    *   Tăng ca 150%: `5 giờ`
    *   Tăng ca 200%: `3 giờ`
    *   Tăng ca 270%: `4 giờ`
    *   Tăng ca 300%: `1 giờ`
*   **Số giờ ca đêm (NS30%)**: 👉 **Ví dụ:** `20.5 giờ`

## 4. Tính lương & Phụ cấp thực tế (Actual Salary)
*   Quy đổi mức lương và phụ cấp cố định thành tiền thực nhận dựa trên ngày công đi làm (Công chính + Phép hưởng lương = 27 ngày).
*   Vì người này đi làm đủ 27/27 ngày công chuẩn, nên họ nhận đủ **Lương cơ bản 10.000.000 VNĐ** và các phụ cấp.

## 5. Tính tiền Tăng ca & Phụ cấp ca đêm (Overtime Amount)
*   **Lương cơ sở tính tăng ca** = Lương cơ bản + Phụ cấp trách nhiệm. 👉 **Ví dụ:** `10.000.000 + 500.000 = 10.500.000 VNĐ`
*   **Tiền tăng ca thực tế** (Minh họa):
    *   *Tăng ca 150% (5 giờ)*: `243.055 VNĐ`
    *   *Tăng ca 200% (3 giờ)*: `145.833 VNĐ`
    *   *Tăng ca 270% (4 giờ)*: `330.555 VNĐ`
    *   *Tăng ca 300% (1 giờ)*: `48.611 VNĐ`
*   **Phụ cấp ca đêm 30%** (20.5 giờ): 👉 **Ví dụ:** `298.958 VNĐ`

## 6. Các khoản điều chỉnh CÓ tính thuế (Taxable Adjustments)
*   **Khoản cộng tính thuế**: Thưởng, phụ cấp không cố định. 👉 **Ví dụ:** `1.000.000 VNĐ`
*   **Khoản trừ tính thuế**: Các khoản phạt. 👉 **Ví dụ:** `-200.000 VNĐ`

## 7. Tổng thu nhập & Thu nhập chịu thuế (Gross / Taxable Income)
*   **Tổng thu nhập (Gross)**: Lương thực tế + Phụ cấp + Tiền tăng ca/ca đêm + Khoản cộng có thuế - Khoản trừ có thuế.
    *   👉 **Ví dụ thực tế:** `14.331.597 VNĐ`
*   **Thu nhập chịu thuế**: Bằng Tổng thu nhập trừ đi các khoản miễn thuế (PC điện thoại 300k, PC cơm miễn thuế 730k,...).
    *   👉 **Ví dụ thực tế:** `12.501.944 VNĐ`

## 8. Trích nộp Bảo hiểm (Insurance)
Dựa trên mức đóng BH là LCB + PC (Mức đóng mẫu trong file là 10.300.000 VNĐ):
*   **Bảo hiểm nhân viên (trừ vào lương)**: 
    *   BHXH 8%: `824.000 VNĐ`
    *   BHYT 1.5%: `154.500 VNĐ`
    *   BHTN 1%: `103.000 VNĐ`
    *   👉 **Tổng BH nhân viên trừ:** `1.081.500 VNĐ`
*   **Bảo hiểm công ty (đóng thêm)**: Xã hội 17.5% (`1.802.500 VNĐ`), Y tế 3% (`309.000 VNĐ`), Thất nghiệp 1% (`103.000 VNĐ`).

## 9. Trích nộp Công đoàn (Union)
*   **Công đoàn nhân viên (`EmpUnion`)**: 👉 **Ví dụ:** `50.000 VNĐ` (Mức trần 1% của BHXH hoặc cố định 50k).
*   **Công đoàn công ty (`CompUnion`)**: 👉 **Ví dụ:** `206.000 VNĐ` (2%).

## 10. Các khoản giảm trừ (Tax Deductions)
*   **Giảm trừ bản thân**: 👉 **Ví dụ:** Cố định `11.000.000 VNĐ/tháng`.
*   **Giảm trừ gia cảnh**: Tính theo số người phụ thuộc.

## 11. Tính Thuế thu nhập cá nhân (PIT - Personal Income Tax)
*   **Thu nhập tính thuế**: = Thu nhập chịu thuế (12.501.944) - Tổng BH nhân viên (1.081.500) - Giảm trừ bản thân (11.000.000).
    *   👉 **Ví dụ thực tế:** `420.444 VNĐ`
*   **Thuế TNCN phải nộp (Bậc 1: 5%)**: 
    *   👉 **Ví dụ thực tế:** `21.022 VNĐ`

## 12. Các khoản điều chỉnh KHÔNG tính thuế (Non-taxable Adjustments)
Được cộng hoặc trừ **sau khi** đã tính xong thuế:
*   **Không tính thuế - Khoản cộng**: 👉 **Ví dụ:** `500.000 VNĐ`
*   **Không tính thuế - Khoản trừ**: 👉 **Ví dụ:** `-450.000 VNĐ`

## 13. Lương thực nhận (Net Take-Home)
Đây là số tiền cuối cùng chuyển khoản cho nhân viên.
*   **Công thức**: Gross (Mục 7) - Bảo hiểm NV - CĐ NV - Thuế TNCN + Khoản cộng (không thuế) - Khoản trừ (không thuế).
*   **Diễn giải số liệu ví dụ**:
    `14.331.597` (Gross) 
    `- 1.081.500` (BHNV) 
    `- 50.000` (Công đoàn) 
    `- 21.022` (Thuế TNCN) 
    `+ 500.000` (Cộng ko thuế) 
    `- 450.000` (Trừ ko thuế)
*   👉 **THỰC NHẬN (NET): `13.229.075 VNĐ`**
