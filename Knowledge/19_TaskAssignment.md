# 19 — Hệ thống Giao việc (Task Assignment Module)

> Tri thức xác minh từ DB `Vietinsoft_Pay`: đọc schema 14 bảng `tblTask_*` + `tblTasks` + đọc source 3 procedure chính (`sp_Task_Save`, `sp_Task_ApproveTask`, `sp_Task_CompleteTask`) qua MCP `mssql-vietinsoft`.

---

## 1. Phân biệt 3 module dễ nhầm

| Module | Prefix bảng | Menu | Mục đích |
|---|---|---|---|
| **Task Management hiện đại** (file này) | `tblTask_*` + master `tblTasks` | `MnuAT001..MnuAT007` (parent `MnuCSM000`) | Giao việc end-to-end: draft → assigned → in progress → in review → done; có duyệt nhiều cấp, subtask, template, recurring, SignalR realtime, notification mobile |
| **Cron job scheduler** | `TaskSchedule` + `TaskHolder` | `MnuMDT289` | Lập lịch chạy job nội bộ ParadiseHRS service (`SendPendingEmail`, `Task_SALCAL`, `Task_TA_ImportAttend`, ...). KHÔNG phải giao việc cho người. |
| **Phân công lao động sản xuất** | `tblLabourAssignTask` | `MnuMDT261` | Master data phân công công đoạn sản xuất (legacy, ít dùng) |
| **Bảng `tblTask` (legacy)** | `tblTask` (10 cột: `TaskID`, `TaskName`, `DueDate`, `ImportanceLevel`, `ColorCode`, `ReminderBefore`, `CurrentAssignee`, `ParticipantsList`, `Details`, `CompleteLevel`) | (không gắn menu nào) | Bảng cũ, không có procedure nào tham chiếu. KHÔNG dùng. |

→ Khi nói "hệ thống giao việc ParadiseHR" mặc định là module ở mục 1 (prefix `tblTask_*`).

---

## 2. Sơ đồ ER (History-versioning design)

```
tblTasks (master)                          tblTask_Projects
├─ TaskID (PK, IDENTITY)                   ├─ ProjectID (PK)
├─ TaskName                                ├─ ProjectName
└─ StatusID                                ├─ Description
                                           └─ IsActive
        │ 1
        │
        │ N
        ▼
tblTask_Tasks (history/version log)  ◄── ParentHistoryID / ParentTaskID (self-ref tree)
├─ HistoryID (PK, IDENTITY) ─────┐
├─ TaskID         (FK tblTasks)  │
├─ ProjectID                     │
├─ AssigneeID (CSV nvarchar(max))│
├─ MainAssigneeID                │
├─ RequestID                     │
├─ ParentTaskID                  │
├─ ParentHistoryID               │
├─ DueDate                       │
├─ ActualStartDate               │
├─ ActualFinishDate              │
├─ StatusID (FK tblTask_Status)  │
├─ Priority                      │
├─ StandardTime                  │
├─ SessionUID                    │
├─ RejectCount                   │
├─ SourceTaskID                  │
├─ dDate / ModifiedDate          │
                                 │
                                 ▼  (mọi bảng vệ tinh link theo HistoryID, KHÔNG link TaskID)
   ├──► tblTask_Approvals    (ApprovalID, HistoryID, ApproverID, StageOrder, ApprovalStatus, Note, CreatedBy, dDate)
   ├──► tblTask_Comments     (CommentID, HistoryID, LoginID, Comment, dDate, ModifiedDate)
   ├──► tblTask_Checklists   (ChecklistID, HistoryID, ItemName, IsDone, LoginID, dDate)
   ├──► tblTask_TimeLine     (TimeLineID, HistoryID, Title, StartDate, EndDate, ProgressPercent)
   ├──► tblTask_TaskProcesses (ProcessID, HistoryID, LoginID, ChangedDate, OldStatusID, NewStatusID)  -- audit log
   ├──► tblTask_TaskTags     (HistoryID, TagID) ──► tblTask_Tags (TagID, TagName, LoginID)
   └──► tblTask_TaskTimeLine_Shadow (HistoryID, TaskID, TaskName, AssigneeID, StatusID, DueDate, Priority, DataHash, SnapshotDate)

tblTask_Templates (cây template)              tblTask_RecurrenceRules
├─ ParentTaskID                                ├─ RecurrenceID
├─ SubTaskID                                   ├─ TemplateTaskID
├─ StandardTime                                ├─ RepeatType / RepeatInterval
├─ ApprovalStatus                              ├─ RepeatDaysOfWeek
├─ IsActive                                    ├─ StartDate / EndDate / DueAfterDays
└─ SortOrder                                   ├─ LastGeneratedDate
                                               └─ IsActive
```

**Điểm cốt lõi**: mọi sửa task ⇒ **append 1 row mới vào `tblTask_Tasks`** (HistoryID mới), KHÔNG update tại chỗ. Các bảng vệ tinh đều khoá theo `HistoryID` → audit-trail bất biến từng phiên bản.

---

## 3. Bảng trạng thái `tblTask_Status` (5 row)

| StatusID | StatusName | Color | Ý nghĩa |
|---|---|---|---|
| 0 | _(không lưu trong bảng)_ | — | **Draft** — `sp_Task_Save` xử lý đặc biệt, auto-delete sau 12h nếu user bỏ |
| 1 | Assigned | `#3b82f6` xanh | Đã giao, chưa nhận |
| 2 | In Progress | `#f97316` cam | Đang thực hiện |
| 3 | In Review | `#6366f1` tím | Hoàn tất, chờ duyệt (chỉ khi `tblTask_Approvals` có row) |
| 4 | Done | `#16a34a` xanh lá | Hoàn thành |
| 5 | Cancelled | `#ef4444` đỏ | Huỷ |

Pipeline tiêu biểu: `0 → 1 → 2 → 3 → 4` (có duyệt) hoặc `0 → 1 → 2 → 4` (không duyệt).

---

## 4. Menu Web (HTML-rendered)

Parent: `MnuCSM000`. Tất cả `IsWeb=0`, ClassName trỏ wrapper procedure (renderer là cặp `*_html`).

| MenuID | ClassName | Renderer | Mobile | Chức năng |
|---|---|---|---|---|
| `MnuAT001` | `sp_Task_TaskList` | `sp_Task_TaskList_html` | ✅ | Danh sách task tổng |
| `MnuAT002` | `sp_Task_TaskDetail` | `sp_Task_TaskDetail_html` | ✅ | Chi tiết 1 task |
| `MnuAT003` | `sp_Task_MyWork` | `sp_Task_MyWork_html` | — | Công việc của tôi |
| `MnuAT004` | `sp_Task_TaskTimeLine` | `sp_Task_TaskTimeLine_html` | — | Khung Gantt TimeLine |
| `MnuAT005` | `sp_TaskListHistory` | `sp_TaskListHistory_html` | — | Lịch sử các phiên bản task |
| `MnuAT007` | `sp_UserHunryTask` | `sp_UserHunryTask_html` | — | Task quá hạn ("đói") |

Chuẩn renderer: theo [17_RendererHtmlJsSafe.md](17_RendererHtmlJsSafe.md). Cache HTML lưu trong `tblHtmlScriptCache`.

---

## 5. Quy trình 6 giai đoạn

### 5.1 Tạo task / draft — `sp_Task_Save`

**Tham số chính**: `@TaskID`, `@HistoryID`, `@TaskName`, `@AssigneeID` (CSV), `@MainAssigneeID`, `@ProjectID`, `@ParentTaskID`, `@DueDate`, `@StatusID` (0=draft, ≥1=submit), `@Priority`, `@StandardTime`, `@TagID`, `@SourceTaskID` (tạo từ template), `@ApprovalStatus` (0/1), `@SessionUID`, `@LoginID`.

Logic (trích từ source):

1. **Normalize**: `@TaskID=0 → NULL`, `@ParentTaskID=0 → NULL`. Resolve `EmployeeIDCurrent` từ `tblSC_Login` theo `@LoginID`. Default `RequestID = EmployeeIDCurrent`.
2. **Draft handling** (`@StatusID=0`):
   - Lấy lại HistoryID draft gần nhất theo `@SessionUID`.
   - `DELETE` draft cũ của user > 12 giờ (`DATEDIFF(HOUR, ISNULL(ModifiedDate, dDate), GETDATE()) > 12`).
3. **Tạo master** nếu `@StatusID>0 AND @TaskID IS NULL AND @TaskName IS NOT NULL`:
   ```sql
   INSERT INTO tblTasks (TaskName, StatusID) VALUES (@TaskName, 1);
   SET @TaskID = SCOPE_IDENTITY();
   ```
4. **Resolve MainAssignee**: nếu rỗng → lấy người đầu tiên trong `STRING_SPLIT(@AssigneeID, ',')`.
5. **Resolve ParentHistoryID** từ `MAX(HistoryID)` của `@ParentTaskID`. Nếu là subtask → **ép `ProjectID = ProjectID của parent`** (không cho subtask khác dự án).
6. **INSERT/UPDATE `tblTask_Tasks`** (append HistoryID mới).
7. **Sync `ProjectID` xuống cây con đệ quy** (CTE).
8. **Tạo approval** nếu `@ApprovalStatus=1`:
   ```sql
   SELECT @MgrID = LineManagerID FROM tblEmployee WHERE EmployeeID = @EmployeeIDCurrent;
   INSERT INTO tblTask_Approvals (HistoryID, ApproverID, ApprovalStatus, StageOrder, dDate, CreatedBy)
   VALUES (@NewHistoryID, @MgrID, 0, 1, GETDATE(), @LoginID);
   ```
   → **Approver mặc định = `LineManagerID` của requester** (cột trong `tblEmployee`). StageOrder bắt đầu từ 1.
9. **Bung template** nếu `@SourceTaskID > 0`: BFS qua `tblTask_Templates` bằng table queue + cursor; mỗi node con tạo row `tblTask_Tasks` mới với `StatusID=1`, kế thừa Assignee/Project/DueDate, copy `StandardTime` từ template.
10. **Upsert tag** vào `tblTask_TaskTags`.
11. **Tổng hợp `StandardTime` lên cây cha đệ quy**: leo ngược `ParentTaskID`, mỗi cha update `StandardTime = SUM(StandardTime của các con — bản ghi mới nhất)`.
12. **SignalR**: `sp_Task_SignalR_Detail_Update`.
13. **Notification "giao việc mới"** (`NotifycationSendID=6`) vào `tblEmailList`:
    - Master task: `INSERT` cho từng giá trị trong `STRING_SPLIT(@AssigneeID, ',')`.
    - Subtask: **gom nhóm theo `ParentHistoryID`** — chỉ subtask đầu tiên tạo row, các subtask sau bị `NOT EXISTS` chặn → tránh spam.
14. **Trigger gửi ngay**: reset `Taskschedule.LastTryDay/NextRunDate = '20190101'` cho `FunctionName='SendPendingEmail'` rồi `EXEC sp_SendEmailPending 3, 'vn'`.

### 5.2 Tiếp nhận — `sp_Task_AcceptTask`

Chuyển `StatusID 1 → 2`, log vào `tblTask_TaskProcesses` (suy luận từ pattern; chưa đọc source).

### 5.3 Làm việc

- `sp_Task_UpdateField` — sửa mô tả/deadline/priority/progress.
- `sp_Task_Checklist_Save` / `sp_Task_Checklist_Toggle` / `sp_Task_Checklist_Delete`.
- `sp_Task_AddComment` / `sp_Task_EditComment` / `sp_Task_DeleteComment`.
- Tạo subtask = gọi lại `sp_Task_Save` với `@ParentTaskID`.
- Realtime: `sp_Task_SignalR_Detail_NewComment`, `sp_Task_SignalR_Detail_SubtaskData`, `sp_Task_SignalR_Detail_Update`, `sp_Task_SmartSignalR`.

### 5.4 Hoàn thành — `sp_Task_CompleteTask`

Tham số: `@HistoryID`, `@LoginID`, `@CompleteSubtasks BIT = 0`.

**Nhánh A — có approval** (`EXISTS tblTask_Approvals WHERE HistoryID=@HistoryID`):
1. Reset toàn bộ `tblTask_Approvals.ApprovalStatus = 0` (Pending), xoá `Note`.
2. `tblTask_Tasks.StatusID = 3` (In Review).
3. Log `tblTask_TaskProcesses` (Old→3).
4. Insert comment `'Đã hoàn thành và gửi yêu cầu phê duyệt'`.
5. Notification `NotifycationSendID=1` (yêu cầu duyệt) cho approver `StageOrder` nhỏ nhất (`ApprovalStatus=0`).

**Nhánh B — không approval**:
1. `tblTask_Tasks.StatusID = 4` (Done).
2. Log `tblTask_TaskProcesses`.
3. Comment `'Đã hoàn thành công việc'`.
4. Notification `NotifycationSendID=4` cho **Assignee + Requester** (UNION).

**Option `@CompleteSubtasks=1`**: CTE đệ quy update cây subtask sang `StatusID=4`, comment `'Hệ thống tự động hoàn thành theo công việc cha'`.

Realtime: `sp_Task_SmartSignalR @ForceReload=0` + `sp_Task_SignalR_Detail_Update`. Sau cùng reset Taskschedule + `EXEC sp_SendEmailPending 3, 'vn'`.

### 5.5 Duyệt — `sp_Task_ApproveTask`

Tham số: `@HistoryID`, `@LoginID`, `@ReviewComments`.

1. Resolve `@CurrentEmployeeID` từ `tblSC_Login`.
2. Tìm `tblTask_Approvals` của user: `HistoryID=@HistoryID AND ApprovalStatus=0 AND ApproverID=@CurrentEmployeeID`, lấy `StageOrder` nhỏ nhất. Nếu không có → `ERROR 'Bạn không có quyền duyệt stage hiện tại của task này'`.
3. Update row đó: `ApprovalStatus=1`, set `Note=@ReviewComments`.
4. So `@CurrentStageOrder` vs `MAX(StageOrder)` của task:
   - **Không phải stage cuối**: comment `'Đã duyệt giai đoạn X - Đồng ý: <Tên>'`, notification `NotifycationSendID=1` cho approver kế tiếp.
   - **Stage cuối**: `tblTask_Tasks.StatusID = 4`, log `tblTask_TaskProcesses`, comment `'Phê duyệt hoàn tất - Đồng ý: <Tên>'`, notification `NotifycationSendID=2` cho Assignee + Requester.
5. Realtime SignalR + flush noti.

Các flow phụ:
- `sp_Task_RejectTask` — tăng `RejectCount`, suy luận đặt `ApprovalStatus=2`.
- `sp_Task_ForwardApproval` — chuyển approver kế tiếp.
- `sp_Task_RemindApprover` — gửi nhắc duyệt.
- `sp_Task_Approval_Save` — cấu hình chuỗi stage trước khi submit.

### 5.6 Tự động hoá

- **`sp_Task_DailyReminder`**: nhắc hàng ngày (job qua `TaskSchedule`).
- **`sp_Task_GenerateRecurringTasks`**: đọc `tblTask_RecurrenceRules`, mỗi rule active đến hạn → clone từ `TemplateTaskID` thành task mới.
- **`sp_Task_TaskTimeLine_CheckChange`**: so `DataHash` trong `tblTask_TaskTimeLine_Shadow` để phát hiện trôi giao diện TimeLine.
- **`sp_Task_Sync` / `sp_Task_SyncClient`**: sync client offline.
- **`sp_Task_NotiApproval`**: template sinh nội dung notification từ `HistoryID`.

---

## 6. Mapping `NotifycationSendID` (queue mobile `tblEmailList.EmailType=10`)

| NotifycationSendID | Ngữ cảnh | Người nhận |
|---|---|---|
| 1 | Gửi yêu cầu duyệt | Approver stage hiện tại |
| 2 | Hoàn tất duyệt cấp cuối | Assignee + Requester |
| 4 | Hoàn thành trực tiếp (không qua duyệt) | Assignee + Requester |
| 6 | Giao việc mới | Assignee (CSV) |

Tất cả `TemplateName='sp_Task_NotiApproval'`, `Identity_Id` là `HistoryID` (master) hoặc `ParentHistoryID` (subtask gom nhóm). Cơ chế đẩy qua module mobile → xem [16_mobile_notification.md](16_mobile_notification.md).

---

## 7. Realtime SignalR

ParadiseHR tích hợp SignalR; các SP push event xuống client:

| Procedure | Khi gọi |
|---|---|
| `sp_Task_SignalR_Detail_Update` | Mỗi action thay đổi task (Save/Approve/Complete/UpdateField) |
| `sp_Task_SignalR_Detail_NewComment` | `sp_Task_AddComment` |
| `sp_Task_SignalR_Detail_SubtaskData` | Sub-task tạo/sửa |
| `sp_Task_SmartSignalR @ForceReload` | Broadcast thông minh tới list view; param force reload |
| `sp_Task_CallSignalR_Reload` | Buộc client reload toàn bộ |

---

## 8. Query mẫu hữu ích

```sql
-- 8.1 Lấy bản hiện hành của task (HistoryID mới nhất theo TaskID)
SELECT t.*
FROM tblTask_Tasks t
JOIN (
    SELECT TaskID, MAX(HistoryID) AS LatestHID
    FROM tblTask_Tasks
    GROUP BY TaskID
) lat ON t.TaskID = lat.TaskID AND t.HistoryID = lat.LatestHID
WHERE t.TaskID = @TaskID;

-- 8.2 Cây subtask đệ quy
WITH SubTree AS (
    SELECT HistoryID, TaskID, ParentTaskID, ParentHistoryID, 0 AS Lvl
    FROM tblTask_Tasks
    WHERE TaskID = @RootTaskID
    UNION ALL
    SELECT t.HistoryID, t.TaskID, t.ParentTaskID, t.ParentHistoryID, s.Lvl + 1
    FROM tblTask_Tasks t
    INNER JOIN SubTree s ON t.ParentTaskID = s.TaskID
)
SELECT * FROM SubTree ORDER BY Lvl, TaskID;

-- 8.3 Pipeline duyệt + người duyệt hiện tại
SELECT a.HistoryID, a.StageOrder, a.ApproverID, e.FullName,
       a.ApprovalStatus, a.Note, a.dDate
FROM tblTask_Approvals a
LEFT JOIN tblEmployee e ON e.EmployeeID = a.ApproverID
WHERE a.HistoryID = @HistoryID
ORDER BY a.StageOrder;

-- 8.4 Lịch sử chuyển trạng thái 1 task
SELECT p.ChangedDate, p.OldStatusID, sOld.StatusName AS OldStatus,
       p.NewStatusID, sNew.StatusName AS NewStatus,
       l.LoginID, e.FullName
FROM tblTask_TaskProcesses p
LEFT JOIN tblTask_Status sOld ON sOld.StatusID = p.OldStatusID
LEFT JOIN tblTask_Status sNew ON sNew.StatusID = p.NewStatusID
LEFT JOIN tblSC_Login l ON l.LoginID = p.LoginID
LEFT JOIN tblEmployee e ON e.EmployeeID = l.EmployeeID
JOIN tblTask_Tasks t ON t.HistoryID = p.HistoryID
WHERE t.TaskID = @TaskID
ORDER BY p.ChangedDate;
```

---

## 9. Checklist khi debug task

1. **Status không chuyển**: query `tblTask_TaskProcesses` xem log transition; check `tblTask_Approvals` có row chặn.
2. **Notification không tới mobile**: check `tblEmailList WHERE TemplateName='sp_Task_NotiApproval' AND SendStatus=0` + xem service `SendPendingEmail` trong `Taskschedule`.
3. **Subtask khác ProjectID parent**: do bypass `sp_Task_Save` (ghi trực tiếp). SP này ép cùng dự án.
4. **Draft còn rác**: `tblTask_Tasks WHERE StatusID=0` — `sp_Task_Save` chỉ dọn draft > 12h khi user save lần khác cùng session.
5. **Giao diện TimeLine sai**: so `tblTask_TaskTimeLine_Shadow.DataHash` với hash hiện tại của task; `sp_Task_TaskTimeLine_CheckChange` chuyên xử lý.
6. **Approver sai**: check `tblEmployee.LineManagerID` của người tạo — đó là approver mặc định stage 1.
