# 15 — Core Employee Query APIs

Reference: [02_db_employee.md](02_db_employee.md) (Employee table), [11_permissions.md](11_permissions.md) (RBAC details).

ParadiseHR routes all employee retrieval queries through two central APIs: `fn_vtblEmployeeList_Bydate` (temporal snapshot) and `sp_getEmployeeListWithPermission` (user-permissions scoped).

```
sp_getEmployeeListWithPermission
   ├── fn_Common_GetAccessID            -- Resolves user's AccessID
   └── fn_vtblEmployeeList_Bydate       -- Fetches temporal snapshot
          └── fn_vEmployeeStatus_ByDate -- Filters active statuses
                 └── tmpEmployeeTree    -- User's subtree (when LoginID is active)
```

---

## 1. Temporal Snapshot: `fn_vtblEmployeeList_Bydate`
Returns employee profiles "as-of" a specific date, merging active profiles with history tables.

### 1.1. Signature & Parameters
```sql
CREATE FUNCTION dbo.fn_vtblEmployeeList_Bydate
(
    @ViewDate   DATE,            -- Target date for temporal mapping
    @EmployeeID NVARCHAR(4000),  -- '-1'/'' = All/Tree; semi-colon delimited string = Specific list (e.g. 'E01;E02')
    @LoginID    INT              -- NULL = Skip tree (All employees); NOT NULL = Scope via tmpEmployeeTree
)
RETURNS TABLE
```

### 1.2. Ingestion Filter Modes
1.  **Direct List Mode**: Enters when `@EmployeeID` is a delimited string. Only returns matching profiles.
2.  **User Tree Mode**: Enters when `@EmployeeID` is `'-1'` or `''` and `@LoginID` is NOT NULL. Limits scope to `tmpEmployeeTree` rows.
3.  **Company-Wide Mode**: Enters when `@EmployeeID` is `'-1'` or `''` and `@LoginID` is NULL. Returns all employees who have status logs before `@ViewDate`. Used by payroll and attendance processes.

### 1.3. Result Schema & Historial Mapping
Integrates `tblEmployee` static data (`te.*`) with temporal joins (the nearest record effective on or before `@ViewDate`):
*   **Organization**: `DivisionID`, `DepartmentID`, `SectionID`, `GroupID` from `tblDivDepSecPos` (MAX `ChangedDate` $\le$ `@ViewDate`).
*   **Rank & Grade**: `PositionID` (`tblPositionHistory`), `EmployeeTypeID` (`tblEmployeeTypeHistory`), `LevelID` (`tblLevelIDHistory`), `CostCenter` (`tblCostCenterHistory`), `PositionTitlesID` (`tblPositionTitlesHistory`).
*   **Contracts**: `ContractID`, `ContractCode`, `ContractStartDay` from `tblLabourContract` (MAX `ContractStartDay` $\le$ `@ViewDate`).
*   **Status**: `EmployeeStatusID`, `TerminateDate` (calculated when `EmployeeStatusID = 20`).
*   **Work Location**: `WorkingPlaceID` from `tblWorkingPlaceHistory` (uses absolute `MAX(WorkingPlaceEffectiveDate)` without `@ViewDate` ceiling).

### 1.4. Query Example
```sql
-- Fetch employee snapshot on a past date
SELECT EmployeeID, FullName, DepartmentID, PositionID, TerminateDate
FROM dbo.fn_vtblEmployeeList_Bydate('2026-03-31', '-1', NULL);
```

---

## 2. Status Evaluator: `fn_vEmployeeStatus_ByDate`
Internal TVF helper called by `fn_vtblEmployeeList_Bydate` to isolate valid profiles.
*   **Workflow**: Reads inputs `@EmployeeID` and `@LoginID` -> splits lists or checks `tmpEmployeeTree` -> resolves the active record from `tblEmployeeStatusHistory` on or before `@ViewDate` via `CROSS APPLY (SELECT TOP 1 ... ORDER BY ChangedDate DESC)`.
*   *Caveat*: Employees without a status history log on or before `@ViewDate` are excluded from results.

---

## 3. Permission Scoped List: `sp_getEmployeeListWithPermission`
Returns active employees that the user is authorized to view.

### 3.1. Signature
```sql
CREATE PROCEDURE dbo.sp_getEmployeeListWithPermission
(
    @LoginID    INT,
    @IsFullName BIT = 1 -- 1 = returns (EmployeeID, FullName); 0 = returns (EmployeeID) only
)
```

### 3.2. Access Rules Logic
Gets user's access level via `fn_Common_GetAccessID` and returns a UNION of:
1.  The employee's own record (obtained by matching `tblSC_Login.EmployeeID`).
2.  All active employees, if access level is **Full Access (`-1`)** and `TerminateDate IS NULL`.
3.  Direct subordinates, if access level is **Manager Access (`1`)** where `LineManagerID = User's EmployeeID` and `TerminateDate IS NULL`.
4.  *Note*: Users with **Customer Access (`2`)** or **Standard Access (`0`)** only see their own profile.

*System usage*: Scopes CRM, KPI, and task lists by joining: `INNER JOIN dbo.sp_getEmployeeListWithPermission(@LoginID, 0) perm ON perm.EmployeeID = <Target_Field>`.
*Caution*: This stored procedure evaluates against the current date (`GETDATE()`) and filters out inactive staff (`TerminateDate IS NULL`). It cannot resolve past organizational hierarchies.

---

## 4. Permission Level Resolver: `fn_Common_GetAccessID`
Returns the user's meta-permission tier.
*   **Evaluation Path**: Reads `tblSC_Login.ParentLoginID` (a `&` delimited string of parent accounts) -> splits IDs -> checks for high-priority permissions in `tblSC_Right_Stored` (where `FullAccess = '32'`) against virtual meta-role objects in `tblSC_Object`.
*   **Returned Access Levels**:
    - `-1` (Full Access): Matches object name `'Full access'`.
    - `1` (Manager Access): Matches object name `'Manager access'` or `'Managers access'`.
    - `2` (Customer Access): Matches object name `'Customer access'`.
    - `0` (Standard User): Default fallback.

---

## 5. Performance Risks & Mitigations
*   **Temporal Loop Degradation**: `fn_vtblEmployeeList_Bydate` performs multiple subqueries on history logs. Avoid calling it iteratively inside loops or `WHERE` clauses. Query it once into a `#temp` table, index it, then perform your joins.
*   **Static Location Inconsistency**: `tblWorkingPlaceHistory` skips the `@ViewDate` constraint, retrieving the absolute newest record. Historical reports tracking location changes must perform manual joins.
