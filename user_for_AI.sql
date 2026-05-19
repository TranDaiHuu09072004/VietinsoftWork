-- 1. Tạo Login cho SQL Server (ở cấp độ Server)
USE [master];
GO
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'ai.sa')
BEGIN
    CREATE LOGIN [ai.sa] WITH PASSWORD = N'VietinsoftAI@2026', 
    CHECK_EXPIRATION = OFF, 
    CHECK_POLICY = OFF;
END
GO

-- 2. Tạo User cho Database cụ thể (Thay [Vietinsoft_Pay] bằng tên thật)
USE [Vietinsoft_Pay];
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'ai.sa')
BEGIN
    CREATE USER [ai.sa] FOR LOGIN [ai.sa];
END
GO

-- 3. Cấp quyền chỉ đọc dữ liệu (SELECT) cho tất cả các bảng và view
ALTER ROLE [db_datareader] ADD MEMBER [ai.sa];

-- 4. Cấp quyền thực thi (EXECUTE) để có thể chạy thử các procedure/function (nếu cần kiểm tra kết quả)
-- Nếu bạn chỉ muốn AI đọc code mà không cho phép chạy procedure, có thể bỏ dòng này.
GRANT EXECUTE TO [ai.sa];

-- 5. Cấp quyền xem định nghĩa (VIEW DEFINITION) để AI có thể đọc code bên trong Procedure, Function, View
GRANT VIEW DEFINITION TO [ai.sa];

-- 6. Đảm bảo quyền VIEW ANY COLUMN ENCRYPTION KEY (nếu có dùng mã hóa)
GRANT VIEW ANY COLUMN ENCRYPTION KEY DEFINITION TO [ai.sa];
GRANT VIEW ANY COLUMN MASTER KEY DEFINITION TO [ai.sa];

PRINT 'Tài khoản [ai.sa] đã được tạo với quyền chỉ đọc và xem định nghĩa code.';
