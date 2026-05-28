-- Fix: Tách _showtoolbarGrid_ -> _showtoolbarGrid_ (reload) + _showtoolbarAdd_ (add)
-- Dựa trên bản duc.sql mới nhất
USE [Paradise_Dev];
GO

DECLARE @def NVARCHAR(MAX) = (SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.sptblCommonControlType_Signed_DUC')));

-- Block cũ: 1 biến cho cả add + reload
DECLARE @old_block NVARCHAR(MAX) = N'
                            onToolbarPreparing: function(e) {
                                if (typeof _showtoolbarGrid_%UID% !== "undefined" && _showtoolbarGrid_%UID% == true) {
                                    // Tìm vị trí columnChooser để chèn vào trước nó
                                    let index = e.toolbarOptions.items.findIndex(i => i.name === "columnChooserButton");
                                    if (index === -1) index = e.toolbarOptions.items.length;

                                    e.toolbarOptions.items.splice(index, 0, {
                                        location: "after",
                                        widget: "dxButton",
                                        options: {
                                            icon: "add",
                                            text: "",
                                            stylingMode: "text",
                                            elementAttr: { style: "color: var(--bs-body-color, #000);" },
                                            onClick: function() {
                                                    add%PKColumnName%();
                                            }
                                        }
                                    }, {
                                        location: "after",
                                        widget: "dxButton",
                                        options: {
                                            icon: "refresh",
                                            stylingMode: "text",
                                            elementAttr: { style: "color: var(--bs-body-color, #000);" },
                                            onClick: function() {
                                                    ReloadData();
                                            }
                                        }
                                    });
                                }
                            },
';

-- Block mới: 2 biến riêng
DECLARE @new_block NVARCHAR(MAX) = N'
                            onToolbarPreparing: function(e) {
                                // Nút thêm (+) — _showtoolbarAdd_<UID>
                                if (typeof _showtoolbarAdd_%UID% !== "undefined" && _showtoolbarAdd_%UID% == true) {
                                    let index = e.toolbarOptions.items.findIndex(i => i.name === "columnChooserButton");
                                    if (index === -1) index = e.toolbarOptions.items.length;

                                    e.toolbarOptions.items.splice(index, 0, {
                                        location: "after",
                                        widget: "dxButton",
                                        options: {
                                            icon: "add",
                                            text: "",
                                            stylingMode: "text",
                                            elementAttr: { style: "color: var(--bs-body-color, #000);" },
                                            onClick: function() {
                                                    add%PKColumnName%();
                                            }
                                        }
                                    });
                                }
                                // Nút reload — _showtoolbarGrid_<UID>
                                if (typeof _showtoolbarGrid_%UID% !== "undefined" && _showtoolbarGrid_%UID% == true) {
                                    let index = e.toolbarOptions.items.findIndex(i => i.name === "columnChooserButton");
                                    if (index === -1) index = e.toolbarOptions.items.length;

                                    e.toolbarOptions.items.splice(index, 0, {
                                        location: "after",
                                        widget: "dxButton",
                                        options: {
                                            icon: "refresh",
                                            stylingMode: "text",
                                            elementAttr: { style: "color: var(--bs-body-color, #000);" },
                                            onClick: function() {
                                                    ReloadData();
                                            }
                                        }
                                    });
                                }
                            },
';

IF CHARINDEX(@old_block, @def) > 0
BEGIN
    PRINT 'Found old block. Replacing...'
    SET @def = REPLACE(@def, @old_block, @new_block);
    SET @def = REPLACE(@def, N'CREATE PROCEDURE', N'ALTER PROCEDURE');
    EXEC sp_executesql @def;
    PRINT 'Done: _showtoolbarGrid_ (reload) + _showtoolbarAdd_ (add) separated.'
END
ELSE
BEGIN
    PRINT 'Old block NOT found. Checking if already updated...'
    IF CHARINDEX('_showtoolbarAdd_%UID%', @def) > 0
        PRINT 'Already updated - no changes needed.'
    ELSE
        PRINT 'ERROR: Cannot find either old or new pattern. SP might be different.'
END
GO
