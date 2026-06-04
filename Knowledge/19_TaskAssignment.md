# 19 — Workflow: Task Assignment System

Reference: [16_mobile_notification.md](16_mobile_notification.md) (Push routing), [07_menu_system.md](07_menu_system.md) (caching & rendering).

ParadiseHR implements an append-only, history-versioned task management module (prefix `tblTask_*`).

## 1. Task Modules Identification
*   **Active Giao Việc (Task System)**: Managed via tables `tblTasks` (master), `tblTask_Tasks` (history/versioning log), and satellite tables `tblTask_*`. Controls menus `MnuAT001` to `MnuAT007`.
*   **Cron Job Scheduler**: Managed via `TaskSchedule` and `TaskHolder`. Schedules system cron processes (e.g. `SendPendingEmail`).
*   **Labour Allocation**: `tblLabourAssignTask` (factory floor operations; legacy).
*   **Bảng `tblTask` (Legacy)**: Old table containing static columns (`TaskID`, `DueDate`). Unused in active stored procedures.

---

## 2. ER Architecture (History-Versioning Model)
To maintain an audit trail, updating a task does not edit rows in-place. Instead, it appends a new row to `tblTask_Tasks` with a new `HistoryID`. All child tables map to `HistoryID`, not `TaskID`.

```
tblTasks (Master table)
   │ 1
   │ N
tblTask_Tasks (Versioning log: HistoryID [PK], TaskID [FK], ProjectID, AssigneeID [CSV], MainAssigneeID, RequestID, ParentTaskID, ParentHistoryID, DueDate, StatusID, Priority, StandardTime, SessionUID, RejectCount)
   │
   ├──► tblTask_Approvals (Approvals tracker: StageOrder, ApprovalStatus [0=Pending, 1=Approved, 2=Rejected], ApproverID)
   ├──► tblTask_Comments (Task conversations: LoginID, Comment)
   ├──► tblTask_Checklists (Sub-check items: ItemName, IsDone)
   ├──► tblTask_TimeLine (Project timeline & progress %)
   ├──► tblTask_TaskProcesses (Audit transition logs: OldStatusID, NewStatusID)
   ├──► tblTask_TaskTags / tblTask_Tags (Tags assignment)
```
*Templates & Recurrences*:
*   `tblTask_Templates`: Templates hierarchy mapping (`ParentTaskID`, `SubTaskID`, `StandardTime`).
*   `tblTask_RecurrenceRules`: Cron rules for generating repeating tasks from templates.

---

## 3. Task Status Mappings (`tblTask_Status`)
*   `0` (Draft): Handled by `sp_Task_Save`. Purged automatically if unmodified for > 12 hours.
*   `1` (Assigned): Dispatched but not accepted yet (Color: `#3b82f6`).
*   `2` (In Progress): Active execution (Color: `#f97316`).
*   `3` (In Review): Review gate (Color: `#6366f1`). Only triggers if `tblTask_Approvals` exists.
*   `4` (Done): Completed task (Color: `#16a34a`).
*   `5` (Cancelled): Aborted task (Color: `#ef4444`).

---

## 4. Key Workflows & System Logics

### 4.1. Save / Draft (`sp_Task_Save`)
*   Creates new `tblTasks` master rows and logs the transaction as a new history row in `tblTask_Tasks`.
*   Assigns `MainAssigneeID` as the first ID in the CSV string if unspecified.
*   Ensures child subtasks match the parent's `ProjectID`.
*   Applies approvals if `@ApprovalStatus = 1`, default approver is the requester's `LineManagerID` (from `tblEmployee`).
*   Binds child templates if `@SourceTaskID > 0` by executing a BFS tree traversal on `tblTask_Templates`.
*   Updates parent task total `StandardTime` recursively by summing active child values.
*   Creates push notifications in `tblEmailList` (`EmailType = 10`, `TemplateName = 'sp_Task_NotiApproval'`, `NotifycationSendID = 6` for new tasks). Subtasks are grouped by `ParentHistoryID` to prevent email spam.

### 4.2. Complete (`sp_Task_CompleteTask`)
*   *With Approvals*: Sets status to `3` (In Review), clears previous approvals, and notifies the first pending approver (`NotifycationSendID = 1`).
*   *Without Approvals*: Sets status to `4` (Done), updates `ActualFinishDate = GETDATE()`, logs comment, and notifies requester/assignees (`NotifycationSendID = 4`).
*   *Subtasks auto-complete* (`@CompleteSubtasks = 1`): Performs a recursive CTE search on child tasks and updates all non-completed nodes to `StatusID = 4` with a system-generated comment.

### 4.3. Approve (`sp_Task_ApproveTask`)
*   Checks permissions against `tblTask_Approvals` for the active `StageOrder`.
*   Updates the stage approval status to `1`.
*   If additional stages remain, notifies the next stage approver (`NotifycationSendID = 1`).
*   If the final stage completes, updates `tblTask_Tasks.StatusID = 4`, sets `ActualFinishDate`, and alerts assignees (`NotifycationSendID = 2`).

### 4.4. Recurring Generator (`sp_Task_GenerateRecurringTasks`)
*   A system job executing via `TaskSchedule` that reads recurrence rules and instantiates task sets.

---

## 5. Mobile & Realtime Integration
*   **FCM Notifications (`tblEmailList.EmailType = 10`)**:
    - `1`: Approval request sent to active stage approver.
    - `2`: Final approval confirmation sent to assignees & requester.
    - `4`: Direct task completion notice.
    - `6`: New task assignment alert.
*   **Realtime SignalR broadcast SPs**:
    - `sp_Task_SignalR_Detail_Update`: General task state updates.
    - `sp_Task_SignalR_Detail_NewComment` / `sp_Task_SignalR_Detail_SubtaskData`.
    - `sp_Task_SmartSignalR @ForceReload`: Dispatches list view refreshes.

---

## 6. Diagnostic Queries
```sql
-- 1. Get current active version (Latest HistoryID) of a task
SELECT t.* FROM tblTask_Tasks t
INNER JOIN (
    SELECT TaskID, MAX(HistoryID) AS LatestHID FROM tblTask_Tasks GROUP BY TaskID
) lat ON t.TaskID = lat.TaskID AND t.HistoryID = lat.LatestHID
WHERE t.TaskID = @TaskID;

-- 2. View approval chain & progress
SELECT a.StageOrder, a.ApproverID, e.FullName, a.ApprovalStatus, a.Note, a.dDate
FROM tblTask_Approvals a LEFT JOIN tblEmployee e ON e.EmployeeID = a.ApproverID
WHERE a.HistoryID = @HistoryID ORDER BY a.StageOrder;

-- 3. Query state transition history of a task
SELECT p.ChangedDate, p.OldStatusID, sOld.StatusName AS OldStatus, p.NewStatusID, sNew.StatusName AS NewStatus, e.FullName
FROM tblTask_TaskProcesses p
INNER JOIN tblTask_Tasks t ON t.HistoryID = p.HistoryID
LEFT JOIN tblTask_Status sOld ON sOld.StatusID = p.OldStatusID
LEFT JOIN tblTask_Status sNew ON sNew.StatusID = p.NewStatusID
LEFT JOIN tblSC_Login l ON l.LoginID = p.LoginID
LEFT JOIN tblEmployee e ON e.EmployeeID = l.EmployeeID
WHERE t.TaskID = @TaskID ORDER BY p.ChangedDate;
```
