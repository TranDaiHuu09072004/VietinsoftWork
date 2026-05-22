
CREATE PROCEDURE [dbo].[sslayoutbody]@LoginID int = 3
as
declare @script nvarchar(max)=N'function createTextboxControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div.dxTextBox(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div.dxTextBox("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createDateboxControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div.dxDateBox(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div.dxDateBox("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createTextAreaControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div.dxTextArea(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div.dxTextArea("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createCheckboxControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div.dxCheckBox(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div.dxCheckBox("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createRadioGroupControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div.dxRadioGroup(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div.dxRadioGroup("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createNumberboxControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div.dxNumberBox(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div.dxNumberBox("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
          if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createColorBoxControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div.dxColorBox(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div.dxColorBox("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createPictureEditControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                config.visible = false;
                div[0].option = config;
                let img = $("<img>").addClass("img-fluid");
                if (config.value) img.attr("src", "data:image/jpg;base64," + config.value);
                let fileUpload = $(`<div>`);
                div.addClass("p-2").append(img, fileUpload);
                config.value = null;
                fileUpload.dxFileUploader({
                    dialogTrigger: div,
                    dropZone: div,
                    ...div[0].option,
                });

                if (paramsControl) {
                    paramsControl[config.ControlNameParam] =
                        fileUpload.dxFileUploader("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createPictureBoxControl(div, config, paramsControl, optionsControl) {
                let img = $("<img>").addClass("img-fluid");
                div.addClass("p-2").append(img);
                return div;
            }

            function createFileButtonControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                let fileUpload = $(`<div>`);
                let fileButton = $(`<div>`).dxButton({
                    ...config,
                    onInitialized: function (arg) {
                        if (config.ControlBackColor)
                            arg.element.css("background-color", config.ControlBackColor);
                        if (config.ControlForeColor)
                            arg.element.css("color", config.ControlForeColor);
                    },
                });

                fileUpload.dxFileUploader({
                    ...config,
                    buttonInstance: fileButton.dxButton("instance"),
                    accept: "*",
                    dialogTrigger: fileButton,
                    multiple: false,
                    visible: false,
                });
                div.append(fileButton, fileUpload);

                if (paramsControl) {
                    paramsControl[config.ControlNameParam] =
                        fileUpload.dxFileUploader("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createDropDownButtonControl(
                div,
                config,
                paramsControl,
                optionsControl
            ) {
  if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div.dxDropDownButton(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] =
                        div.dxDropDownButton("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createDropDownControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div.dxDropDownBox(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div.dxDropDownBox("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createGridControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div[0].option.onCellClick = function (e) { };
                div.dxDataGrid(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div.dxDataGrid("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                    for (const key in config) {
                        if (
                            Object.prototype.hasOwnProperty.call(config, key) &&
                            typeof config[key] == "function"
                        ) {
                            paramsControl[config.ControlNameParam][key] = config[key];
                        }
                    }
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createListControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                div.dxList(div[0].option);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div.dxList("instance");
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                    for (const key in config) {
                        if (
                            Object.prototype.hasOwnProperty.call(config, key) &&
                            typeof config[key] == "function"
                        ) {
                            paramsControl[config.ControlNameParam][key] = config[key];
                        }
                    }
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createPDFViewerControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                var viewer = new ej.pdfviewer.PdfViewer({
                    documentPath:
                        "https://cdn.syncfusion.com/Content/pdf/pdf-succinctly.pdf",
                    resourceUrl:
                        "https://cdn.syncfusion.com/ej2/23.2.6/dist/ej2-pdfviewer-lib",
                });
       viewer.appendTo(div[0]);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = viewer;
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createRichTextControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                var hostUrl = "https://services.syncfusion.com/js/production/";
                var defaultRTE = new ej.richtexteditor.RichTextEditor({
                    toolbarSettings: {
                        items: [
                            "Undo",
                            "Redo",
                            "|",
                            "ImportWord",
                            "ExportWord",
                            "ExportPdf",
                            "|",
                            "Bold",
                            "Italic",
                            "Underline",
                            "StrikeThrough",
                            "InlineCode",
                            "SuperScript",
                            "SubScript",
                            "|",
                            "FontName",
                            "FontSize",
                            "FontColor",
                            "BackgroundColor",
                            "|",
                            "LowerCase",
                            "UpperCase",
                            "|",
                            "Formats",
                            "Alignments",
                            "Blockquote",
                            "|",
                            "NumberFormatList",
                            "BulletFormatList",
                            "|",
                            "Outdent",
                            "Indent",
                            "|",
                            "CreateLink",
                            "Image",
                            "FileManager",
                            "Video",
                            "Audio",
                            "CreateTable",
                            "|",
                            "FormatPainter",
                            "ClearFormat",
                            "|",
                            "EmojiPicker",
                            "Print",
                            "|",
                            "SourceCode",
                            "FullScreen",
                        ],
                    },
                    slashMenuSettings: {
                        enable: true,
                        items: [
                            "Paragraph",
                            "Heading 1",
                            "Heading 2",
                            "Heading 3",
                            "Heading 4",
                            "OrderedList",
                            "UnorderedList",
                            "CodeBlock",
                            "Blockquote",
                            "Link",
                            "Image",
                            "Video",
                            "Audio",
                            "Table",
                            "Emojipicker",
                        ],
                    },
                    insertImageSettings: {
                        saveUrl: hostUrl + "api/RichTextEditor/SaveFile",
                        removeUrl: hostUrl + "api/RichTextEditor/DeleteFile",
                        path: hostUrl + "RichTextEditor/",
                    },
                    importWord: {
                        serviceUrl: hostUrl + "api/RichTextEditor/ImportFromWord",
                    },
                    exportWord: {
                        serviceUrl: hostUrl + "api/RichTextEditor/ExportToDocx",
                        fileName: "RichTextEditor.docx",
                        stylesheet: `
					.e-rte-content {
						font-size: 1em;
						font-weight: 400;
						margin: 0;
					}
				`,
                    },
                    exportPdf: {
                        serviceUrl:
                            "https://ej2services.syncfusion.com/js/development/api/RichTextEditor/ExportToPdf",
                        fileName: "RichTextEditor.pdf",
                        stylesheet: `
					.e-rte-content{
						font-size: 1em;
						font-weight: 400;
						margin: 0;
					}
				`,
                    },
                    fileManagerSettings: {
                        enable: true,
                        path: "/Pictures/Food",
                        ajaxSettings: {
                            url: "https://ej2-aspcore-service.azurewebsites.net/api/FileManager/FileOperations",
                            getImageUrl:
                                "https://ej2-aspcore-service.azurewebsites.net/api/FileManager/GetImage",
                            uploadUrl:
                                "https://ej2-aspcore-service.azurewebsites.net/api/FileManager/Upload",
                            downloadUrl:
                                "https://ej2-aspcore-service.azurewebsites.net/api/FileManager/Download",
                        },
                    },
                    quickToolbarSettings: {
                        table: [
                            "TableHeader",
                            "TableRows",
                            "TableColumns",
                            "TableCell",
                            "-",
                            "BackgroundColor",
                            "TableRemove",
                            "TableCellVerticalAlign",
                            "Styles",
                        ],
                        showOnRightClick: true,
                    },
                    enableXhtml: true,
                    showCharCount: true,
                    enableTabKey: true,
                    placeholder: "Type something or use @ to tag a user...",
                    option: function (name, value) {
                        if (typeof value === "undefined") return this[name];

                        if (this[name] === value) return;

                        this[name] = value;
                    },
                    ...config
                });
                defaultRTE.appendTo(div[0]);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = defaultRTE;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createDocumentEditorControl(
                div,
                config,
                paramsControl,
                optionsControl
            ) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                var hostUrl =
                    "https://services.syncfusion.com/js/production/api/documenteditor/";
                var container = new ej.documenteditor.DocumentEditorContainer({
                    serviceUrl: hostUrl,
                    height: "590px",
                });
                container.appendTo(div[0]);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = container;
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createDocumentEditorControl(
                div,
                config,
                paramsControl,
                optionsControl
            ) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                var hostUrl =
                    "https://services.syncfusion.com/js/production/api/documenteditor/";
                var container = new ej.documenteditor.DocumentEditorContainer({
                    serviceUrl: hostUrl,
                    height: "590px",
                });
                container.appendTo(div[0]);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = container;
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function createBarCodeControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                div[0].option = config;
                var barcode = new ej.barcodegenerator.QRCodeGenerator({
                    width: config.width,
                    height: config.height,
                    mode: "SVG",
                    type: config.BarCodeType,
                    displayText: { visibility: false },
                    value: "",
                });
                barcode.appendTo(div[0]);
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = barcode;
                    if (config.Params)
                        paramsControl[config.ControlNameParam].Params = config.Params;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function CreateHTMLControl(div, config, paramsControl, optionsControl) {
                let html = $(config.value);
                return html;
            }

            function CreateHyperLinkControl(div, config, paramsControl, optionsControl) {
                if (!div) div = $(`<div>`);
                else div = $(div);
                if (config.onInitialized) config.onInitialized(config);
                div[0].option = config;
                div[0].option.element = div;
                div.append(
                    $("<a>")
                        .attr("href", "#")
                        .text(config.Message)
                        .on("click", (event) => {
                            event.preventDefault();
                            config.openFormAction(
                                paramsControl[config.ControlNameParam].value
                            );
                        })
                );
                if (paramsControl) {
                    paramsControl[config.ControlNameParam] = div[0].option;
                }
                if (optionsControl) optionsControl[config.ControlNameParam] = div[0].option;
                return div;
            }

            function onGridViewCellClick(t) {
                let s = t.cellElement;
                let config = { ...t.column };
                config.value = t.value;
                s.html(
                    window[t.column.CreateControlFunction]
                        ? window[t.column.CreateControlFunction](null, config)
                        : t.displayValue
                );
            }

            function convertSqlToJsCondition(sqlCondition, objectName) {
                sqlCondition = sqlCondition
                    .replace(/LIKE\s+''%([^%]+)%''/gi, ''.includes("$1")'') // Contains
                    .replace(/LIKE\s+''%([^%]+)''/gi, ''.endsWith("$1")'') // Ends with
                    .replace(/LIKE\s+''([^%]+)%''/gi, ''.startsWith("$1")''); // Starts with

                sqlCondition = sqlCondition.replace(
                    /([\w\.\[\]]+)\s+IN\s+\(([^)]+)\)/gi,
                    (match, field, values) => {
                        const jsValues = values.split(",").map((v) => v.trim());
                        if (objectName) {
                            field = `${objectName}["${field.replace(/[\[\]]/g, "")}"]`;
                        }
                        return `[${jsValues.join(", ")}].includes(${field})`;
                    }
                );

                sqlCondition = sqlCondition.replace(
                    /([\w\.\[\]]+)\s+BETWEEN\s+([\w\d\.\-]+)\s+AND\s+([\w\d\.\-]+)/gi,
                    (match, field, start, end) => {
                        if (objectName) {
                            field = `${objectName}["${field.replace(/[\[\]]/g, "")}"]`;
                        }
                        return `(${field} >= ${start} && ${field} <= ${end})`;
                    }
                );

                if (objectName) {
                    sqlCondition = sqlCondition.replace(
                        /\[([\w]+)\]/g,
                        `${objectName}["$1"]`
                    );
                } else {
                    sqlCondition = sqlCondition.replace(/\[([\w]+)\]/g, "$1");
                }

                return sqlCondition
                    .replace(/=/g, "==") // Replace "=" with "=="
                    .replace(/(>|<)==/g, "$1=") // Replace ">|<==" with ">|<="
                    .replace(/is not null/gi, "!== null") // Convert "is not null"
                    .replace(/is null/gi, "=== null") // Convert "is null"
                    .replace(/\band\b/gi, "&&") // Convert "And" to "&&"
                    .replace(/\bor\b/gi, "||") // Convert "Or" to "||"
                    .replace(/<>/g, "!="); // Replace "<>" with "!="
            }

            function evaluateCondition(condition, context = {}) {
                try {
                    const func = new Function(
                        ...Object.keys(context),
                        `return ${condition};`
                    );
                    return func(...Object.values(context));
                } catch (error) {
                    console.error(condition);
                    console.error("Error evaluating condition:", error);
                    return false;
                }
            }

            function ParseDefineAction(str) {
                let parts = str.split("|");
                let result = {};
                parts
                    .filter((x) => x)
                    .forEach((item) => {
                        if ((item.match(/=/g) || []).length > 1) {
                            let [tmpKey, tmpValue] = item.split(/=(.*)/s);
                            tmpValue = tmpValue.split("&");
                            let tmpValue1 = {};

                            if (tmpValue[0] && tmpValue[0].startsWith("?ExportName")) {
                                tmpValue1.OnExportParams = {};
                                tmpValue[0] = tmpValue[0].replace(
                                    "?ExportName",
                                    "ExportName"
                                );
                                tmpValue.forEach((tmpItem) => {
                                    let [key, ...rest] = tmpItem.split("=");
                                    if (rest.length > 1) {
                                        let tmpValue2 = [];
                                        rest.join("=")
                                            .split("_")
                                            .forEach((tmpItem1) => {
                                                let [key, value] = tmpItem1.split("=");
                                               tmpValue2.push(key);
                                                tmpValue2.push(value);
                                            });

                                        tmpValue1.OnExportParams[key.replace("@", "")] =
                                            tmpValue2;
                                    } else
                                        tmpValue1.OnExportParams[key.replace("@", "")] =
                                            rest.join("=");
                                });
                            } else
                                tmpValue.forEach((tmpItem) => {
                                    let [key, value] = tmpItem.split("=");
                                    tmpValue1[key.replace("@", "")] = value;
                                });
                            result[tmpKey.replace("@", "")] = tmpValue1;
                        } else {
                            let [key, value] = item.split("=");
                            if (key == "Object" && value && value.includes(".")) {
                                let tmpValue1 = {};
                                value = value.split(".");
                                tmpValue1.ActionDefineType = value[0];
                                tmpValue1.ClassName = value[1];
                                value = tmpValue1;
                            }

                            result[key.replace("@", "")] = value;
                        }
                    });
                return result;
            }

            function convertToHTML(inputString) {
                inputString = inputString.replace(/<color=(.*?)>/gi, (match, color) => {
                    const validColor = isValidCSSColor(color)
                        ? color
                        : convertRGBToHex(color);
                    return `<span style="color: ${validColor};">`;
                });
                inputString = inputString.replace(/<\/color>/gi, "</span>");

                // inputString = inputString.replace(/<size=\+(\d+)>/gi, (match, p1) => `<span style="font-size: ${parseInt(p1) + windowFontSize}px;">`);
                // inputString = inputString.replace(/<size=-(\d+)>/gi, (match, p1) => `<span style="font-size: ${windowFontSize - parseInt(p1)}px;">`);
                // inputString = inputString.replace(/<size=(\d+)>/gi, (match, size) => `<span style="font-size: ${size}px;">`);
                inputString = inputString.replace(
                    /<size=([+-]?\d+|{[\d]+}|[\d]+[a-z%]*)>/gi,
                    (match, size) => {
                        const parsedSize = parseSize(size);
                        return `<span style="font-size: ${parsedSize};">`;
                    }
                );
                inputString = inputString.replace(/<\/size>/gi, "</span>");

                inputString = inputString.replace(
                    /<href=(.*?)>(.*?)<\/href>/g,
                    '' < a href = "$1" target = "_blank" > $2</a > ''
                );

                inputString = inputString.replace(/<br>/g, "<br/>");

                inputString = inputString.replace(/<b>/gi, "<strong>");
                inputString = inputString.replace(/<\/b>/gi, "</strong>");

                inputString = inputString.replace(
                    /<u>/gi,
                    '' < span style = "text-decoration: underline;" > ''
                );
                inputString = inputString.replace(/<\/u>/gi, "</span>");

                return inputString;
            }

            function convertRGBToHex(rgb) {
                let rgbArray = rgb.split(",").map((num) => parseInt(num.trim()));
                if (rgbArray.length === 3) {
                    return `#${rgbArray
                        .map((num) => num.toString(16).padStart(2, "0"))
                        .join("")}`;
 }
       return rgb;
            }

            function isValidCSSColor(color) {
                let s = new Option().style;
                s.color = color;
                return s.color !== "";
            }

            function parseSize(size) {
                if (size.startsWith("{") && size.endsWith("}")) {
                    return `${size.slice(1, -1)}px`;
                } else if (/^\d+x$/.test(size)) {
                    return `${parseInt(size)}em`;
                } else if (/^[+-]?\d+$/.test(size)) {
                    let baseFontSize = parseInt(
                        window.getComputedStyle(document.documentElement).fontSize,
                        10
                    );
                    let sizeAdjustment = parseInt(size);
                    let newSize = baseFontSize + sizeAdjustment;
                    return `${newSize}px`;
                } else if (/^\d+$/.test(size)) {
                    return `${size}px`;
                }
                return size;
            }

            function runSPActionFunction(
                funcitonName = "",
                funcitonNameParam = "",
                classNameParam = "",
                spObject = {},
                actionSuccess = (a) => { },
                actionError = (a) => { }
            ) {
                if (!funcitonNameParam) {
                    funcitonNameParam = Object.keys(spObject).find(
                        (x) => x.toLowerCase().replace("_", "") == "functionname"
                    );
                }

                if (!classNameParam) {
                    classNameParam = Object.keys(spObject).find(
                        (x) => x.toLowerCase().replace("_", "") == "classname"
                    );
                }

                let className = spObject[classNameParam];

                if (!funcitonName) funcitonName = spObject[funcitonNameParam];

                delete spObject[funcitonNameParam];
                delete spObject[classNameParam];

                if (funcitonName.toLowerCase() == "runjs") {
                    CallMethod(
                        funcitonName.toLowerCase() == "runjs" ? "" : className,
                        funcitonName,
                        Object.values(spObject)
                    );
                    return;
                }

                AjaxHPAParadiseParadise({
                    data: {
                        name: funcitonName,
                        param: Object.values(spObject),
                    },
                    success: function (resultData) {
                        let jsonData =
                            typeof resultData === "string"
                                ? JSON.parse(resultData)
                                : resultData;
                        if (actionSuccess) actionSuccess(jsonData);
                    },
                    error: function (xhr, status, error) {
                        if (actionError) actionError(error);
                    },
                });
            }

            async function runSPActionFunctionAsync(
                funcitonName = "",
                funcitonNameParam = "",
                classNameParam = "",
                spObject = {},
                actionSuccess = (a) => { },
                actionError = (a) => { }
            ) {
                if (!funcitonNameParam) {
                    funcitonNameParam = Object.keys(spObject).find(
                        (x) => x.toLowerCase().replace("_", "") == "functionname"
                    );
                }

                if (!classNameParam) {
                    classNameParam = Object.keys(spObject).find(
                        (x) => x.toLowerCase().replace("_", "") == "classname"
                    );
                }

                let className = spObject[classNameParam];

 if (!funcitonName) funcitonName = spObject[funcitonNameParam];

                delete spObject[funcitonNameParam];
                delete spObject[classNameParam];

                if (funcitonName.toLowerCase() == "runjs") {
                    CallMethod(
                        funcitonName.toLowerCase() == "runjs" ? "" : className,
                        funcitonName,
                        Object.values(spObject)
                    );
                    return;
                }

                await AjaxHPAParadiseParadiseAsync({
                    data: {
                        name: funcitonName,
                        param: Object.values(spObject),
                    },
                    success: function (resultData) {
                        let jsonData =
                            typeof resultData === "string"
                                ? JSON.parse(resultData)
                                : resultData;
                        if (actionSuccess) actionSuccess(jsonData);
                    },
                    error: function (xhr, status, error) {
                        if (actionError) actionError(error);
                    },
                });
            }

            function showPopupNotify(
                title,
                content,
                btnOKText = "OK",
                popupWidth = "15vw",
                closePopupFunction = () => { }
            ) {
                var myDialog = DevExpress.ui.dialog.custom({
                    title: title,
                    messageHtml: `<div style="width: ${popupWidth}">${content}</div>`,
                    buttons: [
                        {
                            text: btnOKText,
                            onClick: function (e) {
                                return true;
                            },
                        },
                    ],
                });
                myDialog.show().done(function () {
                    closePopupFunction();
                });
            }

            function decodeHtmlEntities(str) {
                const txt = document.createElement("textarea");
                txt.innerHTML = str;
                return txt.value;
            }

            function copyViaExcelExport(
                gridInstance,
                isSelectedRowsOnly = false,
                copyWithHeader = false,
                loadPanelmessage = "Copying"
            ) {
                let workbook = new ExcelJS.Workbook();
                let sheet = workbook.addWorksheet("dummy");
                let str = "";

                let col = gridInstance.getVisibleColumns();
                col = col.filter((x) => x.dataField !== undefined && x.allowExporting);
                let lastColumn = col[col.length - 1].dataField;

                DevExpress.excelExporter
                    .exportDataGrid({
                        component: gridInstance,
                        worksheet: sheet,
                        selectedRowsOnly: isSelectedRowsOnly,
                        loadPanel: {
                            showPane: false,
                            message: loadPanelmessage,
                        },
                        customizeCell: function (options) {
                            let { gridCell } = options;
                            let field = gridCell.column.dataField;

                            switch (gridCell.rowType) {
                                case "header" && copyWithHeader:
                                    str += `${gridCell.column.caption}\t`;

                                    if (field === lastColumn) {
                                        str += `\r\n`;
                                    }
                                    break;
                                case "data":
                                    if (gridCell.column.dropdownSource) {
                                gridCell.value =
                                            gridCell.column.dropdownSource.find(
                                                (x) =>
                                                    x[gridCell.column.keyExpr] ==
                                                    gridCell.data[gridCell.column.dataField]
                                            )?.[gridCell.column.displayExpr] ??
                                            (gridCell.value ? gridCell.value : "");
                                    } else if (
                                        gridCell.column.CreateControlFunction ==
                                        "createCheckboxControl"
                                    ) {
                                        gridCell.value = gridCell.value
                                            ? String.fromCharCode(parseInt("2713", 16))
                                            : "";
                                    } else if (
                                        gridCell.column.CreateControlFunction ==
                                        "createDateboxControl"
                                    ) {
                                        gridCell.value = DevExpress.localization.formatDate(
                                            gridCell.value,
                                            gridCell.column.displayFormat
                                        );
                                    } else {
                                        gridCell.value =
                                            gridCell.data[gridCell.column.dataField];
                                    }

                                    str += `${gridCell.value ?? ""}\t`;

                                    if (field === lastColumn) {
                                        str += `\r\n`;
                                    }

                                    break;
                                case "group":
                                    if (gridCell.value) str += `${gridCell.value} `;

                                    if (
                                        gridCell.groupSummaryItems !== undefined &&
                                        gridCell.groupSummaryItems.length >= 1
                                    ) {
                                        gridCell.groupSummaryItems.forEach((x) => {
                                            str += ` ${x.name}: ${x.value} `;
                                        });
                                    }

                                    str += `\t`;

                                    if (field === lastColumn) {
                                        str += `\r\n`;
                                    }
                                    break;
                                case "groupFooter":
                                    break;
                                case "totalFooter":
                                    break;
                                default:
                                    break;
                            }
                        },
                    })
                    .then(() => {
                        navigator.clipboard.writeText(str).then(
                            () => { },
                            () => { }
                        );
                    });
            }
            function GetFormatDate(date, format = "yyyy-MM-dd HH:mm:ss") {
                return DevExpress.localization.formatDate(new Date(date), format);
            }
            if (!Object.filter)
                Object.filter = (obj, predicate) =>
                    Object.keys(obj)
                        .filter((key) => predicate(obj[key], key))
                        .reduce((res, key) => ((res[key] = obj[key]), res), {});

            if (!Object.findValue)
       Object.findValue = function (obj, key) {
                    if (!obj) return undefined;
                    let match = Object.keys(obj).find(k => k.toLowerCase() === key.toLowerCase());
                    return match ? obj[match] : undefined;
                };

            function getArrayTypeDistinct(arr) {
                return [...new Set(arr.map((x) => typeof x))];
            }

            function createConditionQuery(filter, schema, comboBoxColumn) {
                let condition = ``;
                if (
                    Array.isArray(filter) &&
                    filter.length == 3 &&
                    ["=", "<", ">"].includes(filter[1])
                ) {
                    if (filter[2] == null) {
                        filter[0] = `ISNULL(${filter[0]} , '''')`;
                        filter[2] = "''''";
                    } else if (typeof filter[2] == "object") {
                        filter[2] = "''" + filter[2].toISOString() + "''";
                    } else if (typeof filter[2] == "number") {
                        filter[2] = "''" + filter[2].toString() + "''";
                    }
                } else if (
                    Array.isArray(filter) &&
                    filter.length == 3 &&
                    Array.isArray(filter[2]) &&
                    filter[2].length == 0
                ) {
                    filter.pop();
                    filter.pop();
                }

                filter.forEach((item) => {
                    let typeList = Array.isArray(item) ? getArrayTypeDistinct(item) : [];
                    if (
                        (Array.isArray(item) && typeList.length > 1) ||
                        (Array.isArray(item) &&
                            typeList.length == 1 &&
                            typeList[0] == "object")
                    ) {
                        condition += `(${createConditionQuery(
                            item,
                            schema,
                            comboBoxColumn
                        )})`;
                    } else if (Array.isArray(item) && typeList.length == 1) {
                        condition += `${item[0]}`;
                        if (
                            schema &&
                            schema.find((x) => x.name == item[0]).type == "System.String"
                        )
                            condition += " COLLATE Latin1_General_CI_AI";
                        if (comboBoxColumn && comboBoxColumn.includes(item[0]))
                            condition += ` like N''${item[2]}''`;
                        else
                            condition += `${item[1] == "contains"
                                    ? ` like N''%${item[2]}%''`
                                    : ` = N''${item[2]}''`
                                }`;
                    } else
                        condition +=
                            " " +
                            (item == null
                                ? "NULL"
                                : item.toLocaleString().toLocaleUpperCase()) +
                            " ";
                });

                return condition;
            }

            function createParamString(param) {
                let paramString = "";
                for (let index = 0; index < param.length; index += 2) {
                    if (index > 0) paramString += ", ";
                    paramString += `${param[index]} = N''''${param[index + 1]}''''`;
                }
                return paramString;
            }

            function transformDateToHierarchy(data) {
                let result = [],
                    col0Map = new Map();

                data.forEach(({ col0, col1, col2, col3, col4, col5, totalCount }) => {
                    if (!col0Map.has(col0)) {
                        let col0Obj = { key: col0, items: [] };
                        col0Map.set(col0, col0Obj);
                        result.push(col0Obj);
                    }

                    if (!col1) return;

                    let col0Obj = col0Map.get(col0),
                        col1Map = col0Obj._col1Map || new Map();

                    if (!col1Map.has(col1)) {
                        let col1Obj = { key: col1, items: [] };
                        if (col2) col1Obj.count = totalCount;
                        col1Map.set(col1, col1Obj);
                        col0Obj.items.push(col1Obj);
                    }

                    col0Obj._col1Map = col1Map;

                    if (!col2) return;

                    let col1Obj = col1Map.get(col1),
                        col2Map = col1Obj._col2Map || new Map();

                    if (!col2Map.has(col2)) {
                        let col2Obj = { key: col2, items: [] };
                        if (col3) col1Obj.count = totalCount;
                        col2Map.set(col2, col2Obj);
                        col1Obj.items.push(col2Obj);
                    }

                    col1Obj._col2Map = col2Map;

                    if (!col3) return;

                    let col2Obj = col2Map.get(col2),
                        col3Map = col2Obj._col3Map || new Map();

                    if (!col3Map.has(col3)) {
                        let col3Obj = { key: col3, items: [] };
                        if (col4) col2Obj.count = totalCount;
                        col3Map.set(col3, col3Obj);
                        col2Obj.items.push(col3Obj);
                    }

                    col2Obj._col3Map = col3Map;

                    if (!col4) return;

                    let col3Obj = col3Map.get(col3),
                        col4Map = col3Obj._col4Map || new Map();

                    if (!col4Map.has(col4)) {
                        let col4Obj = { key: col4, items: [] };
                        if (col5) col3Obj.count = totalCount;
                        col4Map.set(col4, col4Obj);

                        col3Obj.items.push(col4Obj);
                    }

                    col3Obj._col4Map = col4Map;

                    if (col5 != undefined) {
                        let col4Obj = col4Map.get(col4);
                        col4Obj.items.push({
                            key: col5,
                            items: null,
                            count: totalCount,
                        });
                    }
                });

                return result;
            };'
declare @dataMinify nvarchar(max)=N''
exec ssMinifyFile @data=@script, @dataMinify=@dataMinify output
if @dataMinify is not null set @script=@dataMinify
declare @html nvarchar(max)=N'<script>
var errorIcon = `<svg xmlns="http://www.w3.org/2000/svg" width="80" height="94" viewBox="0 0 80 94"><path fill="url(#a)" d="M35.983 89.216c19.873 0 35.983-16.034 35.983-35.811s-16.11-35.811-35.983-35.811S0 33.627 0 53.404s16.11 35.812 35.983 35.812" opacity=".2"/><path fill="#004c39" d="M2.804 83.44A24.84 24.84 0 0 1 1.78 64.898C4.451 57 10.87 50.958 18.948 48.734l2.141 7.703c-5.505 1.516-9.878 5.632-11.697 11.01a16.92 16.92 0 0 0 .696 12.628z"/><path fill="url(#b)" d="M3.224 94a2.41 2.41 0 0 1-2.15-1.31c-2.366-4.626-.51-10.306 4.138-12.662 4.648-2.355 10.355-.508 12.723 4.118a2.393 2.393 0 0 1-1.054 3.225 2.415 2.415 0 0 1-3.24-1.05 4.6 4.6 0 0 0-2.701-2.296 4.63 4.63 0 0 0-3.541.277 4.614 4.614 0 0 0-2.03 6.212 2.393 2.393 0 0 1-1.054 3.224A2.4 2.4 0 0 1 3.224 94"/><path fill="#004c39" d="M65.498 53.165a25.04 25.04 0 0 1-11.862 5.575l-1.413-7.868a17.06 17.06 0 0 0 9.15-4.793 16.95 16.95 0 0 0 4.956-11.645l8.03.167c-.135 6.444-2.72 12.517-7.277 17.1q-.765.768-1.584 1.464"/><path fill="url(#c)" d="M76.666 34.372a9.4 9.4 0 0 1-5.979 2.238 9.42 9.42 0 0 1-6.731-2.653 9.33 9.33 0 0 1-2.874-6.614 2.403 2.403 0 0 1 2.371-2.434 2.404 2.404 0 0 1 2.447 2.36c.04 2.546 2.154 4.586 4.712 4.546a4.62 4.62 0 0 0 3.26-1.403 4.58 4.58 0 0 0 1.309-3.287 2.403 2.403 0 0 1 2.371-2.435A2.404 2.404 0 0 1 80 27.05a9.33 9.33 0 0 1-2.667 6.7 10 10 0 0 1-.666.622Z"/><path fill="url(#d)" d="m3.659 29.132 2.546 4.929a.225.225 0 0 1-.162.325l-1.207.21a.225.225 0 0 0-.16.329l2.774 5.071c.125.228-.172.45-.357.268L1.49 34.763a.225.225 0 0 1 .046-.356l1.33-.762a.225.225 0 0 0 .081-.31L.82 29.78a.225.225 0 0 1 .155-.338l2.443-.43a.23.23 0 0 1 .24.119Z"/><path fill="#004c39" d="M13.555 49.154 18.88 79.12c1.42 7.996 8.403 13.824 16.562 13.824 7.942 0 14.802-5.529 16.453-13.26l6.517-30.531H13.555Z"/><path fill="#fff" d="m27.444 71.528-.208.005-.017-.855-.94.02.018.854-.209.004-.037-1.812.208-.004.016.772.94-.02-.016-.772.208-.004z"/><path fill="#edffc8" d="M35.983 55.753c12.387 0 22.428-2.955 22.428-6.6s-10.04-6.599-22.428-6.599c-12.386 0-22.428 2.955-22.428 6.6s10.041 6.6 22.428 6.6Z"/><path fill="#004c39" d="M57.412 27.124c1.365 9.607-7.693 15.597-19.677 17.283s-22.356-1.569-23.72-11.176c-1.366-9.607 6.793-21.928 18.777-23.615s23.255 7.9 24.62 17.508"/><path fill="url(#e)" d="m45.916 16.85-12.343 1.737c-3.869.545-6.562 4.107-6.015 7.958s4.127 6.53 7.996 5.986l12.343-1.737c3.869-.545 6.562-4.107 6.015-7.958s-4.127-6.53-7.996-5.986"/><path fill="url(#f)" d="m31.73 2.182-.957.182 1.849 9.598.957-.183z"/><path fill="url(#h)" d="M31.389 4.755c.983 0 1.78-.793 1.78-1.772s-.797-1.772-1.78-1.772c-.984 0-1.781.793-1.781 1.772s.797 1.772 1.78 1.772Z"/><path fill="#004c39" d="M38.074 28.153a.8.8 0 0 1-.48-.16l-5.242-3.924a.794.794 0 0 1-.158-1.115.8.8 0 0 1 1.12-.157l5.241 3.923a.793.793 0 0 1 .159 1.115.8.8 0 0 1-.64.318"/><path fill="#004c39" d="M33.482 28.799a.798.798 0 0 1-.639-1.275l3.943-5.216a.803.803 0 0 1 1.12-.158.794.794 0 0 1 .158 1.115l-3.942 5.216a.8.8 0 0 1-.64.318m15.974-2.248a.8.8 0 0 1-.48-.16l-5.242-3.923a.794.794 0 0 1-.158-1.115.803.803 0 0 1 1.12-.158l5.24 3.924a.793.793 0 0 1 .16 1.115.8.8 0 0 1-.64.317"/><path fill="#004c39" d="M44.864 27.197a.799.799 0 0 1-.639-1.275l3.943-5.216a.8.8 0 0 1 1.12-.157.794.794 0 0 1 .158 1.115l-3.942 5.216a.8.8 0 0 1-.64.317"/><path fill="url(#i)" d="M41.843 34.708c.294-.388.71-.66 1.19-.775a2.1 2.1 0 0 1 1.594.251c.48.293.816.754.947 1.3a.537.537 0 0 1-1.044.249 1.035 1.035 0 0 0-1.886-.299 1.02 1.02 0 0 0-.124.778.537.537 0 0 1-1.044.249 2.07 2.07 0 0 1 .367-1.753"/><defs><linearGradient id="a" x1="35.983" x2="35.983" y1="17.594" y2="89.216" gradientUnits="userSpaceOnUse"><stop stop-color="#eaf6ff"/><stop offset="1" stop-color="#f3ffe9"/></linearGradient><linearGradient id="b" x1="9.122" x2="9.122" y1="79.004" y2="94" gradientUnits="userSpaceOnUse"><stop stop-color="#eaf6ff"/><stop offset="1" stop-color="#f3ffe9"/></linearGradient><linearGradient id="c" x1="70.541" x2="70.541" y1="24.69" y2="36.611" gradientUnits="userSpaceOnUse"><stop stop-color="#eaf6ff"/><stop offset="1" stop-color="#f3ffe9"/></linearGradient><linearGradient id="d" x1="4.134" x2="4.134" y1="29.009" y2="40.332" gradientUnits="userSpaceOnUse"><stop stop-color="#eaf6ff"/><stop offset="1" stop-color="#f3ffe9"/></linearGradient><linearGradient id="e" x1="40.735" x2="40.735" y1="16.78" y2="32.601" gradientUnits="userSpaceOnUse"><stop stop-color="#eaf6ff"/><stop offset="1" stop-color="#f3ffe9"/></linearGradient><linearGradient id="f" x1="31.252" x2="33.083" y1="2.273" y2="11.874" gradientUnits="userSpaceOnUse"><stop stop-color="#eaf6ff"/><stop offset="1" stop-color="#f3ffe9"/></linearGradient><linearGradient id="h" x1="31.389" x2="31.389" y1="1.211" y2="4.755" gradientUnits="userSpaceOnUse"><stop stop-color="#eaf6ff"/><stop offset="1" stop-color="#f3ffe9"/></linearGradient><linearGradient id="i" x1="43.503" x2="43.503" y1="33.874" y2="36.871" gradientUnits="userSpaceOnUse"><stop stop-color="#eaf6ff"/><stop offset="1" stop-color="#f3ffe9"/></linearGradient></defs></svg>`;
var DEFAULT_AVATAR_SVG = `<svg viewBox="0 0 200 200" xmlns="http://www.w3.org/2000/svg" style="background:#ebf6ff"><circle cx="100" cy="235" r="100" fill="#a4c3f5" stroke="#7192c7" stroke-width="6"/><circle cx="100" cy="76" r="43" fill="#fde69a" stroke="#e0b958" stroke-width="6"/></svg>`;
var ImageParadiseDefault = `data:image/svg+xml,`+DEFAULT_AVATAR_SVG;

    window.__OpenActiveMenu = window._OpenActiveMenu
    window._OpenActiveMenu = () => {
        try {
            window.__OpenActiveMenu();
        } catch (error) {
            loadparadisemain()
        }
    }
    if (window.ParadiseOption?.AppInfoVersionString?.length > 0 && ParadiseOption.AppInfoVersionString < 2024072015) {
        window.AjaxHPAParadiseAsync = async function (n) { n._Async = 1; AjaxHPAParadise(n); let i = n.data, t = null; if (i.sendEncryption) { let n = JSON.stringify(i); t = EncryptionStringEncryption(n); t != null && t.length > 0 || !window.EncryptionStringEncryptionCore2 || (t = EncryptionStringEncryptionCore2(n)); try { t != null && t.length > 0 || !window.BlazorAppIndex || (t = await BlazorAppIndex.invokeMethodAsync("EncryptionStringEncryptionCore", n, !0, "")) } catch (r) { } } else t = JSON.stringify(n.data); n.data = t; return await $.ajax(n) }
        window.AjaxHPAParadiseParadiseAsync = async function (n) { n._Async = 1; AjaxHPAParadiseParadise(n); let i = n.data, t = null; if (i.sendEncryption) { let n = JSON.stringify(i); t = EncryptionStringEncryption(n); !t && window.EncryptionStringEncryptionCore2 && (t = EncryptionStringEncryptionCore2(n)); try { t != null && t.length > 0 || !window.BlazorAppIndex || (t = await BlazorAppIndex.invokeMethodAsync("EncryptionStringEncryptionCore", n, !0, "")) } catch (r) { } } else t = JSON.stringify(n.data); n.data = t; return await $.ajax(n) }
        window.AjaxHPAParadise = function (n) { n.url || (n.url = IsNullOrEmpty(window.paradiseparadise) ? window.APPLICATIONADDRESS + "/hpa/paradise2" : window.APPLICATION_ADDRESS_File && n.data.name.toLowerCase().includes("paradisefile") ? window.APPLICATION_ADDRESS_File + "/hpa/paradise2" : window.APPLICATION_ADDRESS + "/api/hpa/paradise2"); n.type || (n.type = "POST"); n.cache || (n.cache = !1); let t = n.data; if (t.paradiseparadise = window.paradiseparadise, typeof t.sendEncryption == "undefined" && (t.sendEncryption = !0), t.requestDateTime || (t.requestDateTime = DevExpress.localization.formatDate(new Date, "yyyy-MM-dd HH:mm:ss")), typeof t.requestTime == "undefined" && (t.requestTime = 7200), !n._Async) { if (n.data = JSON.stringify(t), t.sendEncryption) { let t = EncryptionStringEncryption(n.data); if (!t && window.EncryptionStringEncryptionCore2 && (t = EncryptionStringEncryptionCore2(n.data)), !t) { BlazorAppIndex.invokeMethodAsync("EncryptionStringEncryptionCore", n.data, !0, "").then(t => { n.data = t, $.ajax(n) }); return } } $.ajax(n) } }
        window.AjaxHPAParadiseParadise = function (n) { n.url || (n.url = IsNullOrEmpty(window.paradiseparadise) ? window.APPLICATIONADDRESS + "/hpa/paradiseparadise" : window.APPLICATION_ADDRESS + "/api/hpa/paradiseparadise"); n.type || (n.type = "POST"); n.cache || (n.cache = !1); let t = n.data; if (t.paradiseparadise = window.paradiseparadise, typeof t.sendEncryption == "undefined" && (t.sendEncryption = !0), t.requestDateTime || (t.requestDateTime = DevExpress.localization.formatDate(new Date, "yyyy-MM-dd HH:mm:ss")), typeof t.requestTime == "undefined" && (t.requestTime = 7200), !n._Async) { if (n.data = JSON.stringify(t), t.sendEncryption) { let t = EncryptionStringEncryption(n.data); if (!t && window.EncryptionStringEncryptionCore2 && (t = EncryptionStringEncryptionCore2(n.data)), !t) { BlazorAppIndex.invokeMethodAsync("EncryptionStringEncryptionCore", n.data, !0, "").then(t => { n.data = t, $.ajax(n) }); return } } $.ajax(n) } }
    }
    if (!window.loadparadisemain)
        window.loadparadisemain = async function () { function i(n) { window.paradisedata = n; let i = n.data.data, u = i[0][0]; window.MenuJson = i[1]; window.groupColorsMenu = i[2]; window.dataprofileEmpV = i[3]?.[0]; window.QLFullNameDashMobile = u.FullName ?? ""; window.EmployeeID_Login = u.EmployeeID ?? ""; console.log(t); let r = $("#paradisemain"); r.length > 0 || (r = $("#main-layout-diagram")); r.html(t); $("#FullNameLabelView").html(window.QLFullNameDashMobile) } let r = window.HideWaitingPanel; window.HideWaitingPanel = function () { }; ShowWaitingPanel(); let t, n; if (ParadiseOption.AppInfoVersionString.length > 0) [t, n] = await Promise.all([ssGetConfigMobileHTMLCacheAsync("dashboard_mobile"), sptblDataMobileCacheAsync("sp_dashboard_mobile_data", ["LanguageID", window.LanguageID, "LoginID", window.UserID, "IsWeb", window.isWeb])]); else { t = await ssGetConfigMobileHTMLCacheAsync("dashboard_mobile"); let i = 0; while (i++ < 10 && t == null) t = await ssGetConfigMobileHTMLCacheAsync("dashboard_mobile"); n = await sptblDataMobileCacheAsync("sp_dashboard_mobile_data", ["LanguageID", window.LanguageID, "LoginID", window.UserID, "IsWeb", window.isWeb]) } try { i(n) } catch (u) { } window.HideWaitingPanel = r; HideWaitingPanel(); n.loadDataServer && setTimeout(async () => { n = await n.loadDataServer(1), n && i(n) }, 1) }
    if (!window.ssGettblParameterAsync)
        window.ssGettblParameterAsync = async function (n) { let t = await AjaxHPAParadiseAsync({ data: { name: "ssGettblParameter", param: ["Code", n] } }), i = typeof t == "string" ? JSON.parse(t) : t; return i?.data?.[0]?.[0]?.Value ?? null }
    if (!window.ssGetConfigMobileHTMLCacheAsync)
        window.ssGetConfigMobileHTMLCacheAsync = async function (n) { let f, i, t, r = { data: { name: "ssGetConfigMobileHTMLLayout", param: ["TableName", n, "LanguageID", window.LanguageID, "LoginID", window.UserID, "IsWeb", window.isWeb, "TypeLayout", -1] } }, e = window.ParadiseOption != null && ParadiseOption.AppInfoPackageName != null && ParadiseOption.AppInfoPackageName.length > 0, u = JSON.parse(JSON.stringify(r)); if (u = u.data, u.name = "ssGetConfigMobileHTMLCache", e) { i = await paradiseApimobileAsync(u, {}); t = typeof i == "string" ? JSON.parse(i) : i; let n = ""; if (t.data && t.data.length > 0) { let i = t.data[0]; i.length > 0 && (n = i[0].Version, f = i[0].Html) } r.data.param.push("Version"); r.data.param.push(n) } r.timeout = 4444; try { i = await AjaxHPAParadiseAsync(r); t = typeof i == "string" ? JSON.parse(i) : i } catch (o) { } if (t.data && t.data.length > 0) { let n = t.data[0][0]; n && n.Html && (f = n.Html); e && apimobileAjax({}, { MethodName: "MobileSaveDataSqlLite", prs: [JSON.stringify(t.data[0]), "tblHtmlMobileCache", "", ""] }) } return f }
    if (!window.sptblDataMobileCacheAsync)
        window.sptblDataMobileCacheAsync = async function (n, t) { let i, u, r, e = { data: { name: n, param: t } }, s = window.ParadiseOption != null && ParadiseOption.AppInfoPackageName != null && ParadiseOption.AppInfoPackageName.length > 0, f = ""; if (s) { let t = JSON.parse(JSON.stringify(e)); if (t = t.data, t.name = "sptblDataMobileCache", t.param = ["Name", n, "LanguageID", window.LanguageID, "Type", 0], u = await paradiseApimobileAsync(t, {}), r = typeof u == "string" ? JSON.parse(u) : u, r.data && r.data.length > 0) { let n = r.data[0]; n.length > 0 && (f = n[0].Version, i = n[0].Data) } e.data.param.push("ParadiseVersion"); e.data.param.push(f) } let h = async t => { try { if (u = await AjaxHPAParadiseAsync(e), r = typeof u == "string" ? JSON.parse(u) : u, i = r, r.data && r.data.length > 0 ? f = r.data[r.data.length - 1][0].ParadiseVersion : i = null, i != null && s) { let u = [{ Version: f, Data: JSON.stringify(r), Name: n, LanguageID: window.LanguageID, Type: 0 }], i = { MethodName: "MobileSaveDataSqlLite", prs: [JSON.stringify(u), "tblDataMobileCache", "", ""] }; (t = 1) ? await apimobileAjaxAsync({}, i) : apimobileAjax({}, i) } } catch (o) { } if (i) return i = typeof i == "string" && i.length > 0 ? JSON.parse(i) : i, { data: i } }, o = f?.length > 0; o || await h(); i = typeof i == "string" && i.length > 0 ? JSON.parse(i) : i; let c = { data: i, isLocalData: o }; return o && (c.loadDataServer = h), c }
		
	if (!window._getCss) {
		window._getCss = (url) => {
			return new Promise((resolve, reject) => {
				if (document.querySelector(`link[href="${url}"]`)) {
					resolve();
					return;
				}
				const link = document.createElement("link");
				link.rel = "stylesheet";
				link.href = url;
				link.onload = () => resolve();
				link.onerror = () => reject();
				document.head.appendChild(link);
			});
		};
	}
    if (!window._getScript)
        window._getScript = (obj) => {
            obj.dataType = "script"
            obj.cache = true
            $.ajax(obj);
        }
	setTimeout(()=>{
		_getCss("https://cdn.paradisehrm.com/Content/fontawesome7.2.0/css/all.min.css");
		_getCss("https://cdn.paradisehrm.com/Content/bootstrap-icons.min.css");
		
	},1)
</script>

<style type="text/css">
    #MemuMenu {
        display: none !important;
    }

    .BeginLoading {

        overflow: hidden;
        height: 100vh;
        background: linear-gradient(135deg, #e8f5e8, #f9f9f9, #e7f3e7);
        position: relative;
        color: #2e7d32;
        display: flex;
        justify-content: center;
        align-items: center;
        z-index: 9999
    }

    .background-patternBeginLoading {
        position: absolute;
        top: 0;
        left: 0;
        width: 100%;
        height: 100%;
        background-image:
            radial-gradient(circle at 20% 30%, rgba(76, 175, 80, 0.1) 0%, transparent 25%),
            radial-gradient(circle at 80% 70%, rgba(129, 199, 132, 0.08) 0%, transparent 30%),
            radial-gradient(circle at 50% 50%, rgba(102, 187, 106, 0.05) 0%, transparent 40%),
            linear-gradient(45deg, transparent 48%, rgba(255, 255, 255, 0.05) 50%, transparent 52%),
            linear-gradient(-45deg, transparent 48%, rgba(255, 255, 255, 0.03) 50%, transparent 52%);
        background-size: 300px 300px, 400px 400px, 500px 500px, 60px 60px, 60px 60px;
        animation: backgroundMoveBeginLoading 20s ease-in-out infinite;
        z-index: 1;
    }

    .geometric-shapesBeginLoading {
        position: absolute;
        width: 100%;
        height: 100%;
        overflow: hidden;
        z-index: 1;
    }

    .shapeBeginLoading {
        position: absolute;
        opacity: 0.1;
        animation: floatBeginLoading 15s ease-in-out infinite;
    }

    .shape-1BeginLoading {
        width: 80px;
        height: 80px;
        background: linear-gradient(45deg, #4caf50, #81c784);
        border-radius: 20px;
        top: 15%;
        left: 10%;
        animation-delay: 0s;
        transform: rotate(45deg);
    }

    .shape-2BeginLoading {
        width: 60px;
        height: 60px;
        background: linear-gradient(135deg, #66bb6a, #a5d6a7);
        border-radius: 50%;
        top: 25%;
        right: 15%;
        animation-delay: -3s;
    }

    .shape-3BeginLoading {
        width: 100px;
        height: 100px;
        background: linear-gradient(90deg, #81c784, #c8e6c9);
        border-radius: 30px;
        bottom: 20%;
        left: 5%;
        animation-delay: -6s;
        transform: rotate(30deg);
    }

    .shape-4BeginLoading {
        width: 70px;
        height: 70px;
        background: linear-gradient(180deg, #4caf50, #66bb6a);
        clip-path: polygon(50% 0%, 0% 100%, 100% 100%);
        bottom: 30%;
        right: 20%;
        animation-delay: -9s;
    }

    .shape-5BeginLoading {
        width: 90px;
        height: 90px;
        background: linear-gradient(225deg, #81c784, #a5d6a7);
        border-radius: 50% 0 50% 0;
        top: 60%;
        left: 20%;
        animation-delay: -12s;
    }

    .loading-containerBeginLoading {
        position: relative;
        z-index: 2;
        display: flex;
        flex-direction: column;
        align-items: center;
        width: 90%;
        max-width: 400px;
       padding: 30px 20px 20px;
    }

    .logoBeginLoading {
        text-align: center;
        margin-bottom: 30px;
        display: flex;
        flex-direction: column;
        align-items: center;
    }

    .logo-iconBeginLoading {
        width: 250px;
        margin-bottom: 15px;
    }

    .logoBeginLoading h1 {
        font-size: 2.5rem;
        font-weight: 700;
        margin-bottom: 8px;
        background: linear-gradient(90deg, #2e7d32, #4caf50);
        -webkit-background-clip: text;
        background-clip: text;
        color: transparent;
        letter-spacing: -0.5px;
    }

    .logoBeginLoading p {
        font-size: 1rem;
        opacity: 0.9;
        font-weight: 400;
        line-height: 1.4;
        color: #2e7d32;
    }

    .featuresBeginLoading {
        width: 100%;
        margin: 20px 0 30px;
    }

    .feature-itemBeginLoading {
        display: flex;
        align-items: center;
        padding: 16px 0;
        border-bottom: 1px solid rgba(46, 125, 50, 0.2);
        opacity: 1;
    }

    .feature-itemBeginLoading:last-child {
        border-bottom: none;
    }

    /*.feature-itemBeginLoading:nth-child(1) { animation-delay: 0.3s; }
        .feature-itemBeginLoading:nth-child(2) { animation-delay: 0.5s; }
        .feature-itemBeginLoading:nth-child(3) { animation-delay: 0.7s; }
        .feature-itemBeginLoading:nth-child(4) { animation-delay: 0.9s; }*/

    .feature-itemBeginLoading i {
        font-size: 1.5rem;
        color: #4caf50;
        margin-right: 16px;
        width: 30px;
        text-align: center;
    }

    .feature-itemBeginLoading span {
        font-size: 1rem;
        line-height: 1.4;
        color: #2e7d32;
    }

    .copyrightBeginLoading {
        margin-top: 20px;
        text-align: center;
        font-size: 0.85rem;
        color: #2e7d32;
        opacity: 0.8;
        padding-top: 15px;
        border-top: 1px solid rgba(46, 125, 50, 0.2);
    }

    .copyrightBeginLoading .company-nameBeginLoading {
        font-weight: 600;
        color: #1b5e20;
    }

    .loading-textBeginLoading {
        margin-top: 20px;
        font-size: 1rem;
        opacity: 0.8;
        display: flex;
        align-items: center;
        color: #2e7d32;
    }

    .loading-dotsBeginLoading {
        display: inline-block;
        width: 20px;
        text-align: left;
    }

    .loading-dotsBeginLoading::after {
        content: '';
        animation: dotsBeginLoading 1.5s infinite;
    }

    @keyframes dotsBeginLoading {

        0%,
        20% {
            content: '' .'';
        }

        40% {
            content: '' ..'';
        }

        60%,
        100% {
            content: '' ...'';
        }
    }

    @keyframes fadeInBeginLoading {
        from {
            opacity: 0;
        }

        to {
            opacity: 1;
        }
    }

    @keyframes slideInBeginLoading {
        from {
            opacity: 0;
            transform: translateX(-20px);
        }

        to {
            opacity: 1;
            transform: translateX(0);
        }
    }

    @keyframes backgroundMoveBeginLoading {

        0%,
        100% {
            background-position: 0% 0%, 0% 0%, 0% 0%, 0% 0%, 0% 0%;
        }

        50% {
            background-position: 100% 100%, 100% 100%, 100% 100%, 30px 30px, -30px 30px;
        }
    }

    @keyframes floatBeginLoading {

        0%,
        100% {
            transform: translateY(0px) rotate(0deg);
        }

        33% {
            transform: translateY(-20px) rotate(120deg);
        }

        66% {
            transform: translateY(10px) rotate(240deg);
        }
    }

    .decorative-elementBeginLoading {
        position: absolute;
        border-radius: 50%;
        background: radial-gradient(circle, rgba(76, 175, 80, 0.08) 0%, transparent 70%);
        z-index: 1;
}

    .decorative-elementBeginLoading:nth-child(1) {
        width: 150px;
        height: 150px;
        top: -50px;
        right: -50px;
        animation: floatBeginLoading 12s ease-in-out infinite;
    }

    .decorative-elementBeginLoading:nth-child(2) {
        width: 200px;
        height: 200px;
        bottom: -80px;
        left: -80px;
        animation: floatBeginLoading 15s ease-in-out infinite reverse;
    }
</style>
<div class="BeginLoading">
    <div class="background-patternBeginLoading"></div>
    <div class="geometric-shapesBeginLoading">
        <div class="shapeBeginLoading shape-1BeginLoading"></div>
        <div class="shapeBeginLoading shape-2BeginLoading"></div>
        <div class="shapeBeginLoading shape-3BeginLoading"></div>
        <div class="shapeBeginLoading shape-4BeginLoading"></div>
        <div class="shapeBeginLoading shape-5BeginLoading"></div>
    </div>
    <div class="decorative-elementBeginLoading"></div>
    <div class="decorative-elementBeginLoading"></div>

    <div class="loading-containerBeginLoading">
        <div class="logoBeginLoading">
            <img src="https://cdn.paradisehrm.com/Image/BackgroundMobile/paradiselogomain.jpg" onerror="this.onerror=null;this.src=''/CDN/Image/BackgroundMobile/paradiselogomain.jpg'';
                alt=" ParadiseHRM" class="logo-iconBeginLoading">
            <p>Giải pháp hiệu quả cho doanh nghiệp</p>
        </div>

        <div class="spinner-border" role="status" style=" width: 4rem; aspect-ratio: 1; height: unset; ">
            <span class="visually-hidden">Loading...</span>
        </div>
        <div class="featuresBeginLoading">
            <div class="feature-itemBeginLoading">
                <i class="fas fa-clock"></i>
                <span>Chấm công đa nền tảng</span>
            </div>
            <div class="feature-itemBeginLoading">
                <i class="fas fa-calculator"></i>
                <span>Tính lương tự động chính xác</span>
            </div>
            <div class="feature-itemBeginLoading">
                <i class="fas fa-chart-line"></i>
                <span>Báo cáo nhân sự thông minh</span>
            </div>
            <div class="feature-itemBeginLoading">
                <i class="fas fa-shield-alt"></i>
                <span>Bảo mật dữ liệu cao cấp</span>
            </div>
        </div>
        <div class="copyrightBeginLoading">
            © 2025 <span class="company-nameBeginLoading">Vietinsoft Co. Ltd</span><br>
            All rights reserved
        </div>
    </div>
</div>
<script>
    function ShowWaitingPanel() { $(".BeginLoading").show(); } function BuildWaitingPanel() { } //function ShowWaitingPanel() { }
    function HideWaitingPanel() {
        $(".BeginLoading").hide();
        document.querySelectorAll(".dx-overlay-wrapper.dx-popup-wrapper.dx-overlay-shader")
    }
    HideWaitingPanel()
</script>
<script>
'+@script+N'
</script>
<div id="appapp" style="width:100%;">
    <div id="drawer">
        <!--<div id="main-layout-diagram" style="overflow-x:hidden; overflow-y:auto; display:block">-->
        <div id="main-layout-diagram" style="display:block">'

create table #_temptable_ ([TableName] nvarchar(max) null, [LanguageID] nvarchar(max) null, [ScreenType] nvarchar(max) null, [html] nvarchar(max) null)
insert into #_temptable_([TableName], [LanguageID], [ScreenType], [html])
select N'layoutbody' as [TableName], N'en' as [LanguageID], N'0' as [ScreenType], @html as [html]
union all
select N'layoutbody' as [TableName], N'en' as [LanguageID], N'1' as [ScreenType], N'' as [html]
union all
select N'layoutbody' as [TableName], N'en' as [LanguageID], N'2' as [ScreenType], N'' as [html]
union all
select N'layoutbody' as [TableName], N'vn' as [LanguageID], N'0' as [ScreenType], N'' as [html]
union all
select N'layoutbody' as [TableName], N'vn' as [LanguageID], N'1' as [ScreenType], N'' as [html]
union all
select N'layoutbody' as [TableName], N'vn' as [LanguageID], N'2' as [ScreenType], N'' as [html]
update #_temptable_ set html = (select top 1 html from #_temptable_ where len(html) > 0)
declare @LanguageID nVarchar(max) =N'VN'
declare @StyleCSSParadise nVarchar(max) =N''
exec sp_MainStyleCSSParadise @StyleHtml=@StyleCSSParadise output
declare @ScriptParadise nVarchar(max) =N''
if not exists (select * from tblHtmlScriptCache where TableName='sp_MainScriptParadise' and LanguageID=@LanguageID) --
    exec sp_GenerateHTMLScript 'sp_MainScriptParadise'
select @ScriptParadise=html
  from tblHtmlScriptCache
 where TableName='sp_MainScriptParadise'
       and LanguageID=@LanguageID
update #_temptable_ set html = replace(html,'window.__OpenActiveMenu()','if (UserID > 0) loadparadisemain(); else window.__OpenActiveMenu();') where ScreenType = 2
exec sp_SaveData @TableNameTmp='#_temptable_', @TableName='tblHtmlCache', @Command='insert,update', @IsDropTableTmp=0, @IsPrint=0
update t
   set htmlJS=html, htmlJSLocal=html
  from dbo.tblHtmlCache t
 where TableName like '%layoutbody%'


if object_id('tempdb..#__temptable__') is not null drop table #__temptable__
create TABLE #__temptable__ ( [TableName] nvarchar(128), [LanguageID] varchar(5), [ScreenType] varchar(4), [html] nvarchar(max) )
INSERT INTO #__temptable__ ([TableName], [LanguageID], [ScreenType], [html])
VALUES
( N'layoutbodyafter', 'en', '1', N'        </div>
    </div>
</div>
' ),
( N'layoutbodyafter', 'en', '2', N'        </div>
    </div>
</div>
' ),
( N'layoutbodyafter', 'en', '0', N'        </div>
    </div>
</div>
' ),
( N'layoutbodyafter', 'vn', '0', N'        </div>
    </div>
</div>
' ),
( N'layoutbodyafter', 'vn', '1', N'        </div>
    </div>
</div>
' ),
( N'layoutbodyafter', 'vn', '2', N'        </div>
    </div>
</div>
' )

exec sp_SaveData  @TableNameTmp = '#__temptable__' , @TableName = 'tblHtmlCache' , @Command = 'insert,update' , @IsDropTableTmp =0,@IsPrint=0

set nocount on
exec spDropTempDBContetionCurrent
select 1 col into #OnlyScript
exec sp_GenerateHTMLScript 'sp_dashboard_mobile_Beta'
select *
  into #temptable
  from tblHtmlScriptCache
 where TableName='sp_dashboard_mobile_Beta'
update #temptable
   set TableName='dashboard_mobile'
declare @MenuJson nvarchar(max) =N'MemuMenuJson', @FullName nvarchar(max) =N'QLFullNameDashMobile', @PositionName nvarchar(max) =N'QLPositionDashMobile', @EmployeeID nvarchar(max) =N'QLEmployeeIDDashMobile', @DepartmentName nvarchar(max) =N'QLDepartmentDashMobile', @HireDate nvarchar(max) =N'QLHireDateDashMobile', @JsonGroupColor nvarchar(max) =N'[<groupColorsMenu>]'
declare @CameraBarCodeNativePopupXML nvarchar(max) =(select Value from tblParameter where Code='CameraBarCodeNativePopupXML')
declare @CameraMauiPopupXML nvarchar(max) =(select Value from tblParameter where Code='CameraMauiPopupXML')
declare @MobileDateBoxOption nvarchar(max) =(select Value from tblParameter where Code='MobileDateBoxOption')
set @StyleCSSParadise =N''
exec sp_MainStyleCSSParadise @StyleHtml=@StyleCSSParadise output
if object_id('tempdb..#_temptable') is not null
    drop table #_temptable
select LanguageID
  into #_temptable
  from #temptable
 group by LanguageID

while exists (select * from #_temptable)begin
    select top 1 @LanguageID=LanguageID
      from #_temptable
    update t
       set html=replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace(replace( --
		html, 'MemuMenuJson', '[]'
		), 'QLFullNameDashMobile', isnull(@FullName, '')
		), 'QLPositionDashMobile', isnull(@PositionName, '')
		), 'QLEmployeeIDDashMobile', isnull(@EmployeeID, '')
		), 'QLDepartmentDashMobile', isnull(@DepartmentName, '')
		), 'QLHireDateDashMobile', isnull(@HireDate, '')
		), '[<groupColorsMenu>]', '[]'
		), '%Flag_ChangePass%', '0'
		), '%LanguageID%', isnull(cast(@LanguageID as nvarchar(20)), '')
		), '[<sp_MainStyleCSSParadise>]', isnull(@StyleCSSParadise, '')
		), '[<sp_MainScriptParadise>]', ''
		), '[<CameraBarCodeNativePopupXML>]', 'null'
		), '[<CameraMauiPopupXML>]', 'null'
		), '[<MobileDateBoxOption>]', isnull(@MobileDateBoxOption, '')
                       )
      from #temptable t
     where LanguageID=@LanguageID
    delete top(1)from #_temptable
end
exec sp_SaveData @TableNameTmp='#temptable', @TableName='tblHtmlScriptCache', @Command='insert,update', @IsDropTableTmp=0, @IsPrint=0

exec spDropTempDBContetionCurrent
exec sp_GenerateHTMLScript 'sp_dashboard_mobile_Beta'
