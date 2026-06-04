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
- **Truy vấn nhanh**: Knowledge được tách thành nhiều file theo chủ đề (DB schema, workflow, phân quyền, menu, …) thay vì 1 file lớn — Agent chỉ load đúng phần cần thiết.

## Cấu trúc workspace

```
VietinsoftWork/
├── README.md                         ← file này (mô tả mục đích dự án)
├── CLAUDE.md                         ← quy tắc bắt buộc cho Agent mỗi session (bao gồm CRITICAL RULES)
├── UserProfile.md                    ← technology preferences & coding style của team
├── .clinerules / .gemini_rules       ← bridge files load mandatory rules
├── .mcp.json                         ← cấu hình MCP server
├── Knowledge/                        ← KHO TRI THỨC CHÍNH
│   ├── INDEX.md                      ← chỉ mục — bảng map keyword/table/procedure → file
│   ├── 00_quick_context.md           ← tổng quan dự án
│   ├── 01_architecture.md            ← 3 nền tảng + ESS
│   ├── 02_db_employee.md             ← hồ sơ nhân viên
│   ├── 03_db_contract.md             ← hợp đồng lao động
│   ├── 04_db_biometric.md            ← vân tay / khuôn mặt
│   ├── 05_db_attendance.md           ← chấm công (5 kênh + pipeline)
│   ├── 06_db_login_account.md        ← tài khoản đăng nhập
│   ├── 07_menu_system.md             ← logic menu + giao diện
│   ├── 08_workflow_crm.md            ← module CRM
│   ├── 09_workflow_payroll.md        ← pipeline tính lương 10 giai đoạn
│   ├── 10_workflow_performance.md    ← 5 hệ thống đánh giá hiệu suất
│   ├── 11_permissions.md             ← phân quyền RBAC + Data scope
│   ├── 12_CreateMenu.md              ← Skill — tạo menu Web mới
│   ├── 13_Migrate_Menu.md            ← Skill — migrate/update menu
│   ├── 14_ParadiseStyle.md           ← Skill — chuẩn thiết kế giao diện
│   ├── 15_employee_query_apis.md     ← API tra cứu nhân viên theo thời điểm
│   ├── 16_mobile_notification.md     ← Mobile Notification (Firebase/FCM)
│   ├── 17_RendererHtmlJsSafe.md      ← Skill — renderer HTML/JS an toàn
│   ├── 18_FindMenuProcedure.md       ← Skill — tra procedure từ tên menu
│   ├── 19_TaskAssignment.md          ← Hệ thống Giao việc
│   ├── 20_ControlSystem.md           ← HPA Control System
│   ├── 21_SPA_Routing.md             ← SPA Routing & Truyền tham số
│   ├── 22_UI_Helpers.md              ← UI Helpers (alert, confirm)
│   ├── 23_CallAPI.md                 ← Skill — Quy chuẩn gọi API
│   ├── 24_CreateStoredProcedure.md   ← Skill — Thiết kế Stored Procedure
│   ├── 25.HPA_Controls_Guidelines.md ← HPA Controls Guidelines
│   ├── 26_QueryOptimization.md       ← Skill — Chẩn đoán & tối ưu hiệu năng SQL
│   ├── 99_deprecated.md              ← Danh sách item lỗi thời
│   ├── email_batching_guide.md       ← Email Batch (Graph API)
│   └── LOAD_EMPLOYEE_AVATAR_GUIDE.md ← Load Avatar Nhân Viên
├── Clients/                          ← Công cụ đồ thị trực quan & kết nối (Codebase Graph)
├── SQL script/                       ← Script SQL (user tự review & chạy)
│   ├── user_for_AI.sql               ← script phụ trợ (đọc, không thực thi)
│   └── *.sql                         ← các script cleanup, deploy, fix, optimize
└── init_client.py                    ← Khởi tạo không gian làm việc cho dự án con mới
```

## Bắt đầu nhanh

- **Agent** (Claude / Antigravity / cline): đọc [CLAUDE.md](CLAUDE.md) session → load [UserProfile.md](UserProfile.md) - quy trình bắt buộc mỗi session. Entry point tra cứu là [Knowledge/INDEX.md](Knowledge/INDEX.md).
- **Người dùng**: mở thẳng file Knowledge muốn xem (vd: [Knowledge/09_workflow_payroll.md](Knowledge/09_workflow_payroll.md) để xem quy trình tính lương).
- **Tra cứu theo keyword / tên bảng / tên procedure**: mở [Knowledge/INDEX.md](Knowledge/INDEX.md) — có 4 bảng map giúp tìm đúng file.

## Nguyên tắc cốt lõi

1. Không tự suy đoán cấu trúc/nghiệp vụ — mọi khẳng định phải có chứng cứ từ DB hoặc source.
2. DB tool mặc định chỉ đọc — không bao giờ ghi/sửa/xoá khi user chưa yêu cầu rõ ràng trong turn hiện tại.
3. Tri thức mới phát hiện qua DB → ghi ngay vào đúng file Knowledge → INDEX.md được cập nhật nếu tạo file mới.
4. **KHÔNG TỰ Ý COMMIT/PUSH CODE** — chỉ commit khi user yêu cầu rõ ràng.

Chi tiết các quy tắc: xem [CLAUDE.md](CLAUDE.md).

## Nguồn dữ liệu

- **MCP `mssql-vietinsoft`** — SQL Server chứa toàn bộ schema ParadiseHR. Cấu hình ở [.mcp.json](.mcp.json).
- Phiên bản DB tại thời điểm khám phá: tham chiếu các tri thức đã verify trong các file Knowledge.

## Repo

`git@github.com:cuongvu300582-rgb/VietinsoftWork.git`
