# 04 — Database: Sinh trắc học — Vân tay & Khuôn mặt (Biometric)

> Schema bảng vân tay, khuôn mặt, lòng bàn tay. Liên quan: [02_db_employee.md](02_db_employee.md) (link qua `BADGENUMBER`), [05_db_attendance.md](05_db_attendance.md) (`USERINFO` dùng làm định danh chấm công).

Hệ thống tích hợp **schema chuẩn ZKTeco** (ZKTime/ZKAccess). Template sinh trắc **không gắn trực tiếp** vào `tblEmployee`, mà lưu ở các bảng riêng, định danh qua `USERINFO.USERID`.

**Cầu nối định danh:** `USERINFO.BADGENUMBER = tblEmployee.EmployeeID`.

## Bảng `USERINFO` — user trên máy chấm công

- Khoá chính: `USERID` (int).
- Cột định danh chính: `BADGENUMBER` (mã chấm công ↔ `EmployeeID`), `NAME`, `GENDER`, `BIRTHDAY`, `HIREDDAY`, `CardNo`, `PHOTO` (varbinary — ảnh user lưu trên máy), `Deleted`.
- Cột liên quan sinh trắc: `FaceGroup` (nhóm khuôn mặt), `VERIFICATIONMETHOD`, `SecurityLevel`, `VerifyCode`.

## Vân tay (Fingerprint)

| Bảng | Mục đích | Cột chính |
|---|---|---|
| `TEMPLATE` | **Lưu template vân tay đã đăng ký** | `TEMPLATEID` (PK), `USERID` (FK → `USERINFO.USERID`), `FINGERID` (0–9, vị trí ngón), `TEMPLATE`/`TEMPLATE1`/`TEMPLATE2`/`TEMPLATE3`/`TEMPLATE4` (varbinary — template multi-version), `BITMAPPICTURE`/`BITMAPPICTURE2-4` (ảnh bitmap), `Template_Text` (text-encoded để gửi API), `SN` (serial máy đăng ký), `EMACHINENUM`, `DivisionFP`, `Flag`, `DownloadDate` |
| `TEMPLATE_History` | Lịch sử các lần đăng ký | `FINGERID`, `TEMPLATE`, `isBestTemplate` (đánh dấu mẫu tốt nhất) |
| `tblRegisterFingerPrintOnlineImage` | Ảnh đăng ký vân tay qua web/form | `FingerIndexID` (PK), `FingerImage` (varbinary) |

## Khuôn mặt (Face)

| Bảng | Mục đích | Cột chính |
|---|---|---|
| `FaceTemp` | **Lưu template khuôn mặt** | `TEMPLATEID` (PK), `USERID`, `USERNO`, `FACEID`, `TEMPLATE` (varbinary), `Template_Text`, `SIZE`, `VALID`, `VFCOUNT`, `PIN`, `DivisionFP`, `SN`, `DownloadDate` |
| `FaceTemp_History` | Lịch sử template khuôn mặt | `FACEID`, `TEMPLATE`, `isBestTemplate` |
| `tblPending_ProcessFaceTempFromEmployeePhoto` | Hàng đợi sinh face template từ ảnh nhân viên | `EmployeeID`, `PhotoImage` (varbinary), `PhotoImagePath` |

## Lòng bàn tay (Palm) — bổ sung

`Palm`, `PalmTemp` — cấu trúc tương tự `TEMPLATE` nhưng cho lòng bàn tay (`TEMPLATEID`, `TEMPLATE` varbinary).

## Thiết bị & trạng thái upload template

| Bảng | Mục đích |
|---|---|
| `Machines` | Thiết bị chấm công. Cột giám sát sinh trắc: `FingerCapacity`, `FingerCount`, `FaceCapacity`, `FaceCount` |
| `MachinesBadgeNumberUploaded` | Track từng nhân viên đã được đẩy template lên từng máy: cột `Finger`, `Face` (0/1) |
| `tblWorkingDevice`, `tblDeviceCodeInfo` | Mapping/định danh thiết bị làm việc |

## Câu SQL mẫu

```sql
-- Đếm số ngón tay đã đăng ký của 1 nhân viên
SELECT u.BADGENUMBER, u.NAME, COUNT(t.TEMPLATEID) AS FingerCount
FROM USERINFO u
LEFT JOIN TEMPLATE t ON t.USERID = u.USERID
WHERE u.BADGENUMBER = N'<EmployeeID>'
GROUP BY u.BADGENUMBER, u.NAME;

-- Đếm số mẫu khuôn mặt đã đăng ký
SELECT u.BADGENUMBER, COUNT(f.TEMPLATEID) AS FaceCount
FROM USERINFO u
LEFT JOIN FaceTemp f ON f.USERID = u.USERID
WHERE u.BADGENUMBER = N'<EmployeeID>'
GROUP BY u.BADGENUMBER;
```

> Ghi chú: cột `TEMPLATE`, `BITMAPPICTURE*`, `PHOTO`, `FingerImage` đều `varbinary(MAX)` — nặng. Tránh `SELECT *`, chỉ lấy ID/USERID/FINGERID/FACEID trừ khi thực sự cần binary.
