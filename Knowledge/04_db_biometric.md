# 04 — Database: Biometrics (Fingerprint & Face)

Reference: [02_db_employee.md](02_db_employee.md) (linked via `BADGENUMBER` <=> `EmployeeID`), [05_db_attendance.md](05_db_attendance.md) (`USERINFO` mapping).

The system integrates ZKTeco schemas. Biometric templates map via `USERINFO.USERID` rather than directly inside `tblEmployee`.
**Key Bridge**: `USERINFO.BADGENUMBER = tblEmployee.EmployeeID`.

## 1. User Identity Mapping: `USERINFO`
Represents the registered user on physical attendance machines.
*   **Primary Key**: `USERID` (int).
*   **Key Columns**: `BADGENUMBER` (maps to `EmployeeID`), `NAME`, `GENDER`, `BIRTHDAY`, `HIREDDAY`, `CardNo`, `PHOTO` (varbinary - profile image stored on terminal), `Deleted`, `FaceGroup`, `VERIFICATIONMETHOD`, `SecurityLevel`, `VerifyCode`.

## 2. Fingerprint Templates
*   `TEMPLATE`: Active fingerprint templates.
    *   *Columns*: `TEMPLATEID` (PK), `USERID` (FK), `FINGERID` (0–9), `TEMPLATE`/`TEMPLATE1-4` (varbinary multi-version templates), `BITMAPPICTURE`/`BITMAPPICTURE2-4` (bitmap image), `Template_Text` (base64 string for API calls), `SN` (machine serial number), `EMACHINENUM`, `DivisionFP`, `Flag`, `DownloadDate`.
*   `TEMPLATE_History`: Past template registry entries (`FINGERID`, `TEMPLATE`, `isBestTemplate`).
*   `tblRegisterFingerPrintOnlineImage`: Scanned finger image from web UI (`FingerIndexID` (PK), `FingerImage` (varbinary)).

## 3. Facial Templates
*   `FaceTemp`: Active face templates.
    *   *Columns*: `TEMPLATEID` (PK), `USERID`, `USERNO`, `FACEID`, `TEMPLATE` (varbinary), `Template_Text`, `SIZE`, `VALID`, `VFCOUNT`, `PIN`, `DivisionFP`, `SN`, `DownloadDate`.
*   `FaceTemp_History`: Facial history logs (`FACEID`, `TEMPLATE`, `isBestTemplate`).
*   `tblPending_ProcessFaceTempFromEmployeePhoto`: Queue for extracting facial templates from profile photos (`EmployeeID`, `PhotoImage` (varbinary), `PhotoImagePath`).

## 4. Palm Templates & Hardware Management
*   `Palm`, `PalmTemp`: Palm biometric schemas (similar structure to `TEMPLATE`).
*   `Machines`: Attendance machine config (`FingerCapacity`, `FingerCount`, `FaceCapacity`, `FaceCount`).
*   `MachinesBadgeNumberUploaded`: Logs which user templates have been sent to each machine (`Finger`, `Face` binary flags).
*   `tblWorkingDevice`, `tblDeviceCodeInfo`: Device identifier mappings.

## 5. SQL Usage Examples
Avoid `SELECT *` due to heavy `varbinary(MAX)` columns.
```sql
-- Count registered fingerprints of an employee
SELECT u.BADGENUMBER, u.NAME, COUNT(t.TEMPLATEID) AS FingerCount
FROM USERINFO u
LEFT JOIN TEMPLATE t ON t.USERID = u.USERID
WHERE u.BADGENUMBER = N'<EmployeeID>'
GROUP BY u.BADGENUMBER, u.NAME;

-- Count registered face templates
SELECT u.BADGENUMBER, COUNT(f.TEMPLATEID) AS FaceCount
FROM USERINFO u
LEFT JOIN FaceTemp f ON f.USERID = u.USERID
WHERE u.BADGENUMBER = N'<EmployeeID>'
GROUP BY u.BADGENUMBER;
```
