# 99 — Deprecated Registry (Obsolete Components)

This registry records deprecated database objects, tables, columns, parameters, and design conventions confirmed obsolete in ParadiseHR.

## 1. Safety Procedures
*   **Rule**: Never suggest, document, or use the listed components for application development or feature updates.
*   **Database Cleanup**: Do not run `DROP` queries directly. Generate an idempotent cleanup script in `SQL script/cleanup_<scope>_<date>.sql` for user review.

---

## 2. Deprecated Components Registry

### 2.1. ASPX Web Portal Menus
All ASPX-style portal menus (URL referencing a `.aspx` file) are obsolete. Web portal menus now exclusively use HTML-rendered stored procedures (caching via `tblHtmlScriptCache`).
*   **Obsolete Menu IDs (in `MEN_Menu`)**: `MnuAtt1` (Leave History), `MnuAtt3` (Leave Summary), `MnuEmployeeInfo` (Employee Info), `MnuPRL1` (Payslip), `MnuATTAppOT` (Approve OT), `MnuATTOTRe` (OT Registration).
*   **Obsolete Parent Messages (in `tblMD_Message`)**: `MnuWebATT` (Attendance), `MnuWebHRM` (HRM), `MnuWebPRL` (Payroll).
*   *Action*: Clean up references in `MEN_Menu` and `tblMD_Message`. No permission records exist in `tblSC_Object` for these items.

### 2.2. Zalo OA Integration
All components referencing Zalo OA (Official Account API, follower tracking, automated templates, broadcast procedures) are deprecated. Zalo Client APIs or Personal Messaging integrations must be used instead.
*   **Obsolete Tables/Views**: `tblZaloFollowerInfo`.
*   **Obsolete Procedures**: `sp_ZaloSendSMSPaySlip...`, `sp_ZaloSendSMSFor...`.

### 2.3. Legacy Core Features
*   **Table `tblTask`**: Legacy table containing static fields (10 columns: `TaskID`, `DueDate`). Replaced by the append-only versioning system `tblTask_Tasks` (see [19_task_assignment.md](19_task_assignment.md)).
*   **hpaControlRichTextEditor**: Legacy rich text input control. Replaced by `hpaControlRichTextEditorPremium`.

---

## 3. Idempotent Cleanup SQL Template
Place cleanup script in `SQL script/cleanup_obsolete_menu_aspx.sql`:
```sql
SET NOCOUNT ON; SET XACT_ABORT ON;
GO
BEGIN TRY
    BEGIN TRANSACTION;

    -- Delete Menu Access Records
    DELETE FROM tblSC_Right_Stored WHERE ObjectID IN (SELECT ObjectID FROM tblSC_Object WHERE Description IN ('MnuAtt1', 'MnuAtt3'));
    DELETE FROM tblSC_GroupRight WHERE ObjectID IN (SELECT ObjectID FROM tblSC_Object WHERE Description IN ('MnuAtt1', 'MnuAtt3'));
    
    -- Delete Object Registries
    DELETE FROM tblSC_Object WHERE Description IN ('MnuAtt1', 'MnuAtt3');
    DELETE FROM tblMD_Message WHERE MessageID IN ('MnuAtt1', 'MnuAtt3', 'MnuWebATT');
    DELETE FROM MEN_Menu WHERE MenuID IN ('MnuAtt1', 'MnuAtt3');

    COMMIT TRANSACTION;
    PRINT '[OK] Deprecated components clean up completed successfully.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    PRINT 'Error occurred: ' + ERROR_MESSAGE();
    THROW;
END CATCH
GO
```
