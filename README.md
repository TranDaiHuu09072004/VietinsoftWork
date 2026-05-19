# VietinsoftWork — Knowledge Base về ParadiseHR

## Mục đích

Workspace này phục vụ **khám phá, tổng hợp và lưu trữ tri thức** về phần mềm **ParadiseHR** của Vietinsoft. Đây **không phải repo code production** — không build, không deploy, không commit code app. Output duy nhất là **các file tri thức** được kiểm chứng từ database thực tế.

## Bối cảnh

ParadiseHR là hệ thống phần mềm quản trị doanh nghiệp do Vietinsoft phát triển, gồm:

- **Module lõi**: Quản lý hồ sơ nhân viên, Chấm công, Tính lương.
- **Module nghiệp vụ**: Đánh giá hiệu suất, Quản lý giao việc, Đào tạo, CRM, Tuyển dụng.
- **Nền tảng**: Windows Desktop, Web application, Mobile app (Android + iOS — ESS).

Database SQL Server với hàng ngàn bảng/procedure mã hoá nghiệp vụ tiếng Việt + tiếng Anh. Việc dò lại schema/logic mỗi session rất tốn thời gian — Knowledge base này tích luỹ phát hiện để các session sau không phải tra lại.

## Ý nghĩa

- **Tri thức được kiểm chứng**: mọi thông tin trong các file Knowledge đều được trích từ DB thực tế qua MCP `mssql-vietinsoft`, source procedure, hoặc xác nhận của user. Không có suy đoán.
- **Tự học** (self-learning): mỗi lần khám phá ra điều mới, Agent ghi lại ngay vào file Knowledge tương ứng — giúp kho tri thức lớn dần và chính xác lên theo thời gian.
- **Truy vấn nhanh**: Knowledge được tách thành 12 file theo chủ đề (DB schema, workflow, phân quyền, menu, …) thay vì 1 file lớn — Agent chỉ load đúng phần cần thiết.

## Cấu trúc workspace

```
VietinsoftWork/
├── README.md                    ← file này (mô tả mục đích dự án)
├── CLAUDE.md                    ← quy tắc bắt buộc cho Agent mỗi session
├── Vietinsoft_Agent_Skill.md    ← bản gốc các CRITICAL RULES
├── .mcp.json                    ← cấu hình MCP server mssql-vietinsoft
├── user_for_AI.sql              ← script SQL phụ trợ (đọc, không thực thi)
└── Knowledge/                   ← KHO TRI THỨC CHÍNH
    ├── INDEX.md                 ← chỉ mục — bảng map keyword/table/procedure → file
    ├── 00_quick_context.md      ← tổng quan dự án
    ├── 01_architecture.md       ← 3 nền tảng + ESS
    ├── 02_db_employee.md        ← hồ sơ nhân viên
    ├── 03_db_contract.md        ← hợp đồng lao động
    ├── 04_db_biometric.md       ← vân tay / khuôn mặt
    ├── 05_db_attendance.md      ← chấm công (5 kênh + pipeline)
    ├── 06_db_login_account.md   ← tài khoản đăng nhập
    ├── 07_menu_system.md        ← logic menu + giao diện
    ├── 08_workflow_crm.md       ← module CRM
    ├── 09_workflow_payroll.md   ← pipeline tính lương 10 giai đoạn
    ├── 10_workflow_performance.md ← 5 hệ thống đánh giá hiệu suất
    └── 11_permissions.md        ← phân quyền RBAC + data scope
```

## Bắt đầu nhanh

- **Agent** (Claude / Antigravity): đọc [CLAUDE.md](CLAUDE.md) — quy trình 5 bước bắt buộc mỗi session. Entry point tra cứu là [Knowledge/INDEX.md](Knowledge/INDEX.md).
- **Người dùng**: mở thẳng file Knowledge muốn xem (vd: [Knowledge/09_workflow_payroll.md](Knowledge/09_workflow_payroll.md) để xem quy trình tính lương).
- **Tra cứu theo keyword / tên bảng / tên procedure**: mở [Knowledge/INDEX.md](Knowledge/INDEX.md) — có 4 bảng map giúp tìm đúng file.

## Nguyên tắc cốt lõi

1. Không tự suy đoán cấu trúc/nghiệp vụ — mọi khẳng định phải có chứng cứ từ DB hoặc source.
2. DB tool mặc định chỉ đọc — không bao giờ ghi/sửa/xoá khi user chưa yêu cầu rõ ràng trong turn hiện tại.
3. Tri thức mới phát hiện qua DB → ghi ngay vào đúng file Knowledge → INDEX.md được cập nhật nếu tạo file mới.

Chi tiết các quy tắc: xem [CLAUDE.md](CLAUDE.md).

## Nguồn dữ liệu

- **MCP `mssql-vietinsoft`** — SQL Server chứa toàn bộ schema ParadiseHR. Cấu hình ở [.mcp.json](.mcp.json).
- Phiên bản DB tại thời điểm khám phá: tham chiếu các tri thức đã verify trong các file Knowledge.

## Repo

`git@github.com:cuongvu300582-rgb/VietinsoftWork.git`
