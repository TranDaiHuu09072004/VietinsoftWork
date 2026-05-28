GO
if object_id('[dbo].[sp_hpaControlCheckBox]') is null
	EXEC ('CREATE PROCEDURE [dbo].[sp_hpaControlCheckBox] as select 1')
GO

ALTER PROCEDURE [dbo].[sp_hpaControlCheckBox]
    @TableName VARCHAR(256) = ''
AS
BEGIN
    -- =========================================================================
    -- hpaControlCheckBox - READONLY MODE
    -- =========================================================================
    UPDATE #temptable SET
        loadUI = N'
            let Instance%ColumnName%%UID% = null;
            let $container%ColumnName%%UID% = $("#%UID%");

            let %ColumnName%%UID%Value = false;

            function normalizeBool%ColumnName%%UID%(val) {
                return val === true || val === 1 || val === "1" || val === "true";
            }

            function renderCheckbox%ColumnName%%UID%(isChecked) {
                const checkedHtml = "<div style=\"display: flex; justify-content: left; height: 100%;\"><svg width=\"18\" height=\"18\" viewBox=\"0 0 18 18\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"><rect width=\"18\" height=\"18\" rx=\"4\" fill=\"rgba(21, 115, 71, 1)\"></rect><polyline points=\"4,9 7.5,13 14,5\" stroke=\"#fff\" stroke-width=\"2.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\" fill=\"none\"></polyline></svg></div>";
                const uncheckedHtml = "<div style=\"display: flex; justify-content: left; height: 100%;\"><div style=\"width: 18px; height: 18px; border: 2px solid rgba(21, 115, 71, 1); border-radius: 4px;\"></div></div>";
                $container%ColumnName%%UID%.html(isChecked ? checkedHtml : uncheckedHtml);
            }

            renderCheckbox%ColumnName%%UID%(%ColumnName%%UID%Value);

            Instance%ColumnName%%UID% = {
                setValue: function(val) {
                    %ColumnName%%UID%Value = normalizeBool%ColumnName%%UID%(val);
                    renderCheckbox%ColumnName%%UID%(%ColumnName%%UID%Value);
                },
                getValue: function() {
                    return %ColumnName%%UID%Value ? 1 : 0;
                },
                option: function(name, value) {
                    if (name === "value") {
                        this.setValue(value);
                    }
                },
                repaint: function() { },
                clearValidationError: function() { }
            };
        '
    WHERE [Type] = 'hpaControlCheckBox' AND [ReadOnly] = 1;

    -- =========================================================================
    -- hpaControlCheckBox - AUTOSAVE MODE
    -- =========================================================================
    UPDATE #temptable SET
        loadUI = N'
            let Instance%ColumnName%%UID% = null;
            let $container%ColumnName%%UID% = $("#%UID%");

            let %ColumnName%%UID%Value = false;
            let _saving%ColumnName%%UID% = false;
            let _autoSave%ColumnName%%UID% = (%AutoSave% === 1);
            let _readOnly%ColumnName%%UID% = (%ReadOnly% === 1);

            function normalizeBool%ColumnName%%UID%(val) {
                return val === true || val === 1 || val === "1" || val === "true";
            }

            function renderCheckbox%ColumnName%%UID%(isChecked) {
                const checkedHtml = "<div style=\"display: flex; justify-content: left; height: 100%;\"><svg width=\"18\" height=\"18\" viewBox=\"0 0 18 18\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"><rect width=\"18\" height=\"18\" rx=\"4\" fill=\"rgba(21, 115, 71, 1)\"></rect><polyline points=\"4,9 7.5,13 14,5\" stroke=\"#fff\" stroke-width=\"2.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\" fill=\"none\"></polyline></svg></div>";
                const uncheckedHtml = "<div style=\"display: flex; justify-content: left; height: 100%;\"><div style=\"width: 18px; height: 18px; border: 2px solid rgba(21, 115, 71, 1); border-radius: 4px;\"></div></div>";
                $container%ColumnName%%UID%.html(isChecked ? checkedHtml : uncheckedHtml);
                $container%ColumnName%%UID%.css("cursor", _readOnly%ColumnName%%UID% ? "default" : "pointer");
            }

            async function saveValue%ColumnName%%UID%(newVal) {
                if (_saving%ColumnName%%UID%) return;

                try {
                    _saving%ColumnName%%UID% = true;
                    const dataJSON = JSON.stringify(["%tableId%", ["%ColumnName%"], [newVal]]);

                    let id1 = window.currentRecordID_%ColumnIDName%;
                    if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                        id1 = cellInfo.data["%ColumnIDName%"] || id1;
                    }
                    let currentRecordIDValue = [id1];
                    let currentRecordID = ["%ColumnIDName%"];

                    if ("%ColumnIDName2%" && "%ColumnIDName2%".trim() !== "") {
                        let id2 = currentRecordID_%ColumnIDName2%;
                        if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                            id2 = cellInfo.data["%ColumnIDName2%"] || id2;
                        }
                        currentRecordIDValue.push(id2);
                        currentRecordID.push("%ColumnIDName2%");
                    }

                    const idValsJSON = JSON.stringify([currentRecordIDValue, currentRecordID]);
                    const json = await saveFunction(dataJSON, idValsJSON);

                    const dtError = json.data[json.data.length - 1] || [];
                    if (dtError.length > 0 && dtError[0].Status === "ERROR") {
                        uiManager.showAlert({ type: "error", message: dtError[0]?.Message || "%SaveErrorMessage%" });
                        return;
                    }

                    try { obj.%ColumnName% = newVal; } catch (e) { }

                    if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                        try {
                            const grid = cellInfo.component;
                            grid.cellValue(cellInfo.rowIndex, "%ColumnName%", newVal);
                            grid.repaint();
                        } catch (syncErr) {
                            console.warn("[Grid Sync] CheckBox sync failed:", syncErr);
                        }
                    }
                } catch (err) {
                    console.error(err);
                    uiManager.showAlert({ type: "error", message: "%SaveErrorMessage%" });
                } finally {
                    _saving%ColumnName%%UID% = false;
                }
            }

            function toggleValue%ColumnName%%UID%() {
                if (_readOnly%ColumnName%%UID%) return;
                %ColumnName%%UID%Value = !%ColumnName%%UID%Value;
                renderCheckbox%ColumnName%%UID%(%ColumnName%%UID%Value);
                if (_autoSave%ColumnName%%UID%) {
                    saveValue%ColumnName%%UID%(%ColumnName%%UID%Value ? 1 : 0);
                }
            }

            $container%ColumnName%%UID%.off("click").on("click", toggleValue%ColumnName%%UID%);

            renderCheckbox%ColumnName%%UID%(%ColumnName%%UID%Value);

            Instance%ColumnName%%UID% = {
                setValue: function(val) {
                    %ColumnName%%UID%Value = normalizeBool%ColumnName%%UID%(val);
                    renderCheckbox%ColumnName%%UID%(%ColumnName%%UID%Value);
                },
                getValue: function() {
                    return %ColumnName%%UID%Value ? 1 : 0;
                },
                option: function(name, value) {
                    if (name === "value") {
                        this.setValue(value);
                    }
                },
                repaint: function() { },
                clearValidationError: function() { },
                _suppressValueChangeAction: function() { },
                _resumeValueChangeAction: function() { }
            };
        '
    WHERE [Type] = 'hpaControlCheckBox' AND [ReadOnly] = 0 AND [AutoSave] = 1;

    -- =========================================================================
    -- hpaControlCheckBox - NO AUTOSAVE MODE
    -- =========================================================================
    UPDATE #temptable SET
        loadUI = N'
            let Instance%ColumnName%%UID% = null;
            let $container%ColumnName%%UID% = $("#%UID%");

            let %ColumnName%%UID%Value = false;
            let _saving%ColumnName%%UID% = false;
            let _autoSave%ColumnName%%UID% = (%AutoSave% === 1);
            let _readOnly%ColumnName%%UID% = (%ReadOnly% === 1);

            function normalizeBool%ColumnName%%UID%(val) {
                return val === true || val === 1 || val === "1" || val === "true";
            }

            function renderCheckbox%ColumnName%%UID%(isChecked) {
                const checkedHtml = "<div style=\"display: flex; justify-content: left; height: 100%;\"><svg width=\"18\" height=\"18\" viewBox=\"0 0 18 18\" fill=\"none\" xmlns=\"http://www.w3.org/2000/svg\"><rect width=\"18\" height=\"18\" rx=\"4\" fill=\"rgba(21, 115, 71, 1)\"></rect><polyline points=\"4,9 7.5,13 14,5\" stroke=\"#fff\" stroke-width=\"2.2\" stroke-linecap=\"round\" stroke-linejoin=\"round\" fill=\"none\"></polyline></svg></div>";
                const uncheckedHtml = "<div style=\"display: flex; justify-content: left; height: 100%;\"><div style=\"width: 18px; height: 18px; border: 2px solid rgba(21, 115, 71, 1); border-radius: 4px;\"></div></div>";
                $container%ColumnName%%UID%.html(isChecked ? checkedHtml : uncheckedHtml);
                $container%ColumnName%%UID%.css("cursor", _readOnly%ColumnName%%UID% ? "default" : "pointer");
            }

            async function saveValue%ColumnName%%UID%(newVal) {
                if (_saving%ColumnName%%UID%) return;

                try {
                    _saving%ColumnName%%UID% = true;
                    const dataJSON = JSON.stringify(["%tableId%", ["%ColumnName%"], [newVal]]);

                    let id1 = window.currentRecordID_%ColumnIDName%;
                    if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                        id1 = cellInfo.data["%ColumnIDName%"] || id1;
                    }
                    let currentRecordIDValue = [id1];
                    let currentRecordID = ["%ColumnIDName%"];

                    if ("%ColumnIDName2%" && "%ColumnIDName2%".trim() !== "") {
                        let id2 = currentRecordID_%ColumnIDName2%;
                        if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.data) {
                            id2 = cellInfo.data["%ColumnIDName2%"] || id2;
                        }
                        currentRecordIDValue.push(id2);
                        currentRecordID.push("%ColumnIDName2%");
                    }

                    const idValsJSON = JSON.stringify([currentRecordIDValue, currentRecordID]);
                    const json = await saveFunction(dataJSON, idValsJSON);

                    const dtError = json.data[json.data.length - 1] || [];
                    if (dtError.length > 0 && dtError[0].Status === "ERROR") {
                        uiManager.showAlert({ type: "error", message: dtError[0]?.Message || "%SaveErrorMessage%" });
                        return;
                    }

                    try { obj.%ColumnName% = newVal; } catch (e) { }

                    if (typeof cellInfo !== "undefined" && cellInfo && cellInfo.component) {
                        try {
                            const grid = cellInfo.component;
                            grid.cellValue(cellInfo.rowIndex, "%ColumnName%", newVal);
                            grid.repaint();
                        } catch (syncErr) {
                            console.warn("[Grid Sync] CheckBox sync failed:", syncErr);
                        }
                    }
                } catch (err) {
                    console.error(err);
                    uiManager.showAlert({ type: "error", message: "%SaveErrorMessage%" });
                } finally {
                    _saving%ColumnName%%UID% = false;
                }
            }

            function toggleValue%ColumnName%%UID%() {
                if (_readOnly%ColumnName%%UID%) return;
                %ColumnName%%UID%Value = !%ColumnName%%UID%Value;
                renderCheckbox%ColumnName%%UID%(%ColumnName%%UID%Value);
                if (_autoSave%ColumnName%%UID%) {
                    saveValue%ColumnName%%UID%(%ColumnName%%UID%Value ? 1 : 0);
                }
            }

            $container%ColumnName%%UID%.off("click").on("click", toggleValue%ColumnName%%UID%);

            renderCheckbox%ColumnName%%UID%(%ColumnName%%UID%Value);

            Instance%ColumnName%%UID% = {
                setValue: function(val) {
                    %ColumnName%%UID%Value = normalizeBool%ColumnName%%UID%(val);
                    renderCheckbox%ColumnName%%UID%(%ColumnName%%UID%Value);
                },
                getValue: function() {
                    return %ColumnName%%UID%Value ? 1 : 0;
                },
                option: function(name, value) {
                    if (name === "value") {
                        this.setValue(value);
                    }
                    if (name === "readOnly") {
                        _readOnly%ColumnName%%UID% = !!value;
                        renderCheckbox%ColumnName%%UID%(%ColumnName%%UID%Value);
                    }
                    if (name === "autoSave") {
                        _autoSave%ColumnName%%UID% = !!value;
                    }
                },
                repaint: function() { },
                clearValidationError: function() { },
                _suppressValueChangeAction: function() { },
                _resumeValueChangeAction: function() { }
            };
        '
    WHERE [Type] = 'hpaControlCheckBox' AND [ReadOnly] = 0 AND [AutoSave] = 0;

    -- =========================================================================
    -- hpaControlCheckBox - LOAD DATA
    -- =========================================================================
    UPDATE #temptable SET
        loadData = N'
            if (typeof Instance%ColumnName%%UID% !== "undefined" && Instance%ColumnName%%UID%) {
                Instance%ColumnName%%UID%.setValue(obj.%ColumnName%);
            }
        '
    WHERE [Type] = 'hpaControlCheckBox';
END
GO