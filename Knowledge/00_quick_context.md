# 00 — Quick Context (Tổng quan ParadiseHR — đọc 60 giây)

> File này là entry-point ngắn. Sau khi đọc, mở [INDEX.md](INDEX.md) để biết file nào chứa tri thức cụ thể bạn cần.

## Dự án

**ParadiseHR** (sản phẩm của Vietinsoft) là một hệ thống phần mềm quản trị doanh nghiệp, gồm các module:

- **Lõi**: Quản lý hồ sơ nhân viên, Chấm công, Tính lương.
- **Nghiệp vụ**: Quản lý giao việc, Đánh giá hiệu suất, Đào tạo, CRM, Tuyển dụng.

## Repo

- Remote: `git@github.com:cuongvu300582-rgb/VietinsoftWork.git`.

## Nguồn dữ liệu xác thực

- **MCP server `mssql-vietinsoft`** — SQL Server, cấu hình ở [`.mcp.json`](../.mcp.json).
- **File tham khảo SQL**: [`user_for_AI.sql`](../user_for_AI.sql) — đọc để hiểu context, KHÔNG được thực thi trừ khi user yêu cầu rõ ràng.

## Workspace mục đích

Workspace này không viết code production. Mục tiêu: **tra cứu — tổng hợp — ghi lại tri thức** về hệ thống ParadiseHR. Mọi tri thức mới phát hiện qua DB phải được ghi lại vào file Knowledge tương ứng.
