import sys
import re

with open('d:\\VietinsoftWork\\sp_KPIListDataCollection_html.sql', 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Fix GridKC Toolbar Responsive
grid_toolbar_old = """        #GridKC .dx-toolbar .dx-toolbar-items-container {
            height: auto;
            min-height: 56px;
            flex-wrap: wrap;
            align-items: center;
            row-gap: 6px;
            margin-bottom: 15px;
        }"""

grid_toolbar_new = """        #GridKC .dx-toolbar .dx-toolbar-items-container {
            height: auto;
            min-height: 56px;
            display: flex !important;
            flex-wrap: wrap;
            align-items: center;
            justify-content: space-between;
            gap: 10px;
            margin-bottom: 15px;
        }

        #GridKC .dx-toolbar-before {
            flex: 0 1 auto;
            flex-wrap: wrap;
        }

        #GridKC .dx-toolbar-after {
            flex: 1 1 250px;
            flex-wrap: nowrap !important;
            justify-content: flex-end;
        }

        #GridKC .dx-toolbar-after .dx-item:has(.dx-datagrid-search-panel) {
            flex: 1 1 auto !important;
            width: 100%;
            max-width: 350px;
        }

        @media (max-width: 850px) {
            #GridKC .dx-toolbar-before,
            #GridKC .dx-toolbar-after {
                flex: 1 1 100% !important;
                width: 100% !important;
                justify-content: flex-start !important;
            }
            
            #GridKC .dx-toolbar-after .dx-item:has(.dx-datagrid-search-panel) {
                max-width: 100%;
            }
        }"""

content = content.replace(grid_toolbar_old, grid_toolbar_new)

# 2. Fix Modal Content Responsive
modal_old = """        #dataCollectionModal.show {
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            min-height: 100vh;
            background: rgba(19, 16, 16, .8) !important;
        }

        .modal-backdrop.show {
            background: rgba(0, 0, 0, 0.65);
            backdrop-filter: blur(1px);
        }

        #dataCollectionModal .modal-dialog {
            margin: 0 !important;
            width: 90vw;
            max-width: 90vw;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }

        .modal-content {
            margin-top: 50px;
            border: none !important;
            box-shadow: none !important;
            width: 100%;
            max-height: 90vh;
            overflow-y: auto;
            scrollbar-width: none;
            -ms-overflow-style: none;
        }

        .modal-content::-webkit-scrollbar {
            display: none;
        }"""

modal_new = """        #dataCollectionModal.show {
            display: flex !important;
            align-items: center !important;
            justify-content: center !important;
            min-height: 100vh;
            background: rgba(19, 16, 16, .8) !important;
        }

        .modal-backdrop.show {
            background: rgba(0, 0, 0, 0.65);
            backdrop-filter: blur(1px);
        }

        #dataCollectionModal .modal-dialog {
            margin: 0 auto !important;
            width: 90vw;
            max-width: 90vw;
            display: flex;
            align-items: center;
            justify-content: center;
            min-height: 100vh;
        }

        .modal-content {
            margin-top: 20px;
            border: none !important;
            box-shadow: none !important;
            width: 100%;
            max-height: 90vh;
            overflow-y: auto;
            scrollbar-width: none;
            -ms-overflow-style: none;
        }

        .modal-content::-webkit-scrollbar {
            display: none;
        }

        @media (max-width: 768px) {
            #dataCollectionModal .modal-dialog {
                width: 95vw !important;
                max-width: 95vw !important;
                min-height: auto;
                margin: 20px auto !important;
            }
            .modal-content {
                max-height: calc(100vh - 40px);
                margin-top: 0;
            }
            /* Đảm bảo form field không tràn */
            #dataCollectionForm .col-md-4, #dataCollectionForm .col-md-8 {
                width: 100% !important;
                margin-bottom: 5px;
            }
            #dataCollectionForm label {
                word-wrap: break-word;
                white-space: normal;
            }
        }

        @media (max-width: 480px) {
            #dataCollectionModal .modal-dialog {
                width: 100vw !important;
                max-width: 100vw !important;
                margin: 0 !important;
                min-height: 100vh;
            }
            .modal-content {
                max-height: 100vh;
                margin-top: 0;
                border-radius: 0 !important;
            }
            .modal-footer {
                flex-wrap: wrap;
                justify-content: center;
                gap: 8px;
            }
            .modal-footer button {
                flex: 1 1 auto;
                width: 100%;
                margin: 0 !important;
            }
        }"""

content = content.replace(modal_old, modal_new)

# 3. Fix Toolbar filter Responsive
filter_old = """        /* Responsive toolbar styles */
        .dc-filter {
            flex-wrap: wrap !important;
            gap: 3px !important;
        }

        @media (max-width: 1200px) {
            .dc-filter {
                flex-direction: column !important;
                align-items: flex-start !important;
                gap: 6px !important;
            }

            .dc-filter>div {
                display: flex !important;
                flex-wrap: wrap !important;



                gap: 6px !important;
                width: 100% !important;
            }

            #dcFilterEmployeeToolbar {
                width: 140px !important;
                min-width: 140px !important;
            }
        }

        @media (max-width: 768px) {
            .dc-filter {
                gap: 4px !important;
            }

            .dc-filter button {
                padding: 4px 8px !important;
                font-size: 11px !important;
            }

            .dc-filter input[type="date"] {
                padding: 4px !important;
font-size: 11px !important;
           }

            #dcFilterEmployeeToolbar {
                width: 120px !important;
                min-width: 120px !important;
            }
        }"""

filter_new = """        /* Responsive toolbar styles */
        .dc-filter {
            flex-wrap: wrap !important;
            gap: 8px !important;
        }

        @media (max-width: 1200px) {
            .dc-filter>div {
                display: flex !important;
                flex-wrap: wrap !important;
                gap: 6px !important;
            }

            #dcFilterEmployeeToolbar {
                width: 140px !important;
                min-width: 140px !important;
            }
        }

        @media (max-width: 768px) {
            .dc-filter {
                gap: 4px !important;
            }

            .dc-filter button {
                padding: 6px 10px !important;
                font-size: 12px !important;
            }

            .dc-filter input[type="date"] {
                padding: 4px !important;
                font-size: 12px !important;
            }

            #dcFilterEmployeeToolbar {
                width: 120px !important;
                min-width: 120px !important;
            }
        }"""

content = content.replace(filter_old, filter_new)

with open('d:\\VietinsoftWork\\sp_KPIListDataCollection_html.sql', 'w', encoding='utf-8') as f:
    f.write(content)

print("Replaced!")
