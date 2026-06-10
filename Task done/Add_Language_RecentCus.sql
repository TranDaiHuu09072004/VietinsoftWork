-- =========================================================================
-- Kịch bản thêm ngôn ngữ cho biến %RecentCus% trong bảng tblMD_Message
-- =========================================================================

-- Tiếng Việt
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'RecentCus' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) 
    VALUES ('RecentCus', 'VN', N'Khách hàng gần đây');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %RecentCus%';
END
ELSE
BEGIN
    UPDATE tblMD_Message 
    SET Content = N'Khách hàng gần đây' 
    WHERE MessageID = 'RecentCus' AND Language = 'VN';
    PRINT N'Đã cập nhật ngôn ngữ Tiếng Việt cho %RecentCus%';
END
GO

-- Tiếng Anh
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'RecentCus' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) 
    VALUES ('RecentCus', 'EN', N'Recent Customers');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %RecentCus%';
END
ELSE
BEGIN
    UPDATE tblMD_Message 
    SET Content = N'Recent Customers' 
    WHERE MessageID = 'RecentCus' AND Language = 'EN';
    PRINT N'Đã cập nhật ngôn ngữ Tiếng Anh cho %RecentCus%';
END
GO

-- =========================================================================
-- Kịch bản thêm ngôn ngữ cho biến %Recalculate% và %RecalculateData%
-- =========================================================================

-- Recalculate (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'Recalculate' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('Recalculate', 'VN', N'Tính toán lại');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %Recalculate%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Tính toán lại' WHERE MessageID = 'Recalculate' AND Language = 'VN';
END
GO

-- Recalculate (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'Recalculate' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('Recalculate', 'EN', N'Recalculate');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %Recalculate%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Recalculate' WHERE MessageID = 'Recalculate' AND Language = 'EN';
END
GO

-- RecalculateData (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'RecalculateData' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('RecalculateData', 'VN', N'Tính lại dữ liệu');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %RecalculateData%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Tính lại dữ liệu' WHERE MessageID = 'RecalculateData' AND Language = 'VN';
END
GO

-- RecalculateData (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'RecalculateData' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('RecalculateData', 'EN', N'Recalculate Data');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %RecalculateData%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Recalculate Data' WHERE MessageID = 'RecalculateData' AND Language = 'EN';
END
GO

-- =========================================================================
-- Kịch bản thêm ngôn ngữ cho các biến mới được yêu cầu
-- =========================================================================

-- @CompanyFullName (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = '@CompanyFullName' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('@CompanyFullName', 'VN', N'Tên công ty');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %@CompanyFullName%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Tên công ty' WHERE MessageID = '@CompanyFullName' AND Language = 'VN';
END
GO

-- @CompanyFullName (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = '@CompanyFullName' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('@CompanyFullName', 'EN', N'Company Name');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %@CompanyFullName%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Company Name' WHERE MessageID = '@CompanyFullName' AND Language = 'EN';
END
GO

-- StatusID (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'StatusID' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('StatusID', 'VN', N'Trạng thái');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %StatusID%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Trạng thái' WHERE MessageID = 'StatusID' AND Language = 'VN';
END
GO

-- StatusID (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'StatusID' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('StatusID', 'EN', N'Status');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %StatusID%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Status' WHERE MessageID = 'StatusID' AND Language = 'EN';
END
GO

-- TaxCode (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'TaxCode' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('TaxCode', 'VN', N'Mã số thuế');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %TaxCode%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Mã số thuế' WHERE MessageID = 'TaxCode' AND Language = 'VN';
END
GO

-- TaxCode (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'TaxCode' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('TaxCode', 'EN', N'Tax Code');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %TaxCode%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Tax Code' WHERE MessageID = 'TaxCode' AND Language = 'EN';
END
GO

-- InchargePerson (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'InchargePerson' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('InchargePerson', 'VN', N'Người phụ trách');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %InchargePerson%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Người phụ trách' WHERE MessageID = 'InchargePerson' AND Language = 'VN';
END
GO

-- InchargePerson (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'InchargePerson' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('InchargePerson', 'EN', N'In-charge Person');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %InchargePerson%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'In-charge Person' WHERE MessageID = 'InchargePerson' AND Language = 'EN';
END
GO

-- PhoneNumber (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'PhoneNumber' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('PhoneNumber', 'VN', N'Số điện thoại');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %PhoneNumber%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Số điện thoại' WHERE MessageID = 'PhoneNumber' AND Language = 'VN';
END
GO

-- PhoneNumber (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'PhoneNumber' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('PhoneNumber', 'EN', N'Phone Number');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %PhoneNumber%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Phone Number' WHERE MessageID = 'PhoneNumber' AND Language = 'EN';
END
GO

-- ContractName (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'ContractName' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('ContractName', 'VN', N'Tên hợp đồng');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %ContractName%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Tên hợp đồng' WHERE MessageID = 'ContractName' AND Language = 'VN';
END
GO

-- ContractName (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'ContractName' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('ContractName', 'EN', N'Contract Name');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %ContractName%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Contract Name' WHERE MessageID = 'ContractName' AND Language = 'EN';
END
GO

-- contract.StartDate (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'contract.StartDate' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('contract.StartDate', 'VN', N'Ngày bắt đầu');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %contract.StartDate%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Ngày bắt đầu' WHERE MessageID = 'contract.StartDate' AND Language = 'VN';
END
GO

-- contract.StartDate (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'contract.StartDate' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('contract.StartDate', 'EN', N'Start Date');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %contract.StartDate%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Start Date' WHERE MessageID = 'contract.StartDate' AND Language = 'EN';
END
GO

-- contract.EndDate (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'contract.EndDate' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('contract.EndDate', 'VN', N'Ngày kết thúc');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %contract.EndDate%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Ngày kết thúc' WHERE MessageID = 'contract.EndDate' AND Language = 'VN';
END
GO

-- contract.EndDate (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'contract.EndDate' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('contract.EndDate', 'EN', N'End Date');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %contract.EndDate%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'End Date' WHERE MessageID = 'contract.EndDate' AND Language = 'EN';
END
GO

-- CRM_Receivable (VN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'CRM_RECEIVABLE' AND Language = 'VN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('CRM_RECEIVABLE', 'VN', N'Phải thu');
    PRINT N'Đã thêm ngôn ngữ Tiếng Việt cho %CRM_RECEIVABLE%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Phải thu' WHERE MessageID = 'CRM_RECEIVABLE' AND Language = 'VN';
END
GO

-- CRM_Receivable (EN)
IF NOT EXISTS (SELECT 1 FROM tblMD_Message WHERE MessageID = 'CRM_RECEIVABLE' AND Language = 'EN')
BEGIN
    INSERT INTO tblMD_Message (MessageID, Language, Content) VALUES ('CRM_RECEIVABLE', 'EN', N'Receivable');
    PRINT N'Đã thêm ngôn ngữ Tiếng Anh cho %CRM_RECEIVABLE%';
END
ELSE
BEGIN
    UPDATE tblMD_Message SET Content = N'Receivable' WHERE MessageID = 'CRM_RECEIVABLE' AND Language = 'EN';
END
GO
