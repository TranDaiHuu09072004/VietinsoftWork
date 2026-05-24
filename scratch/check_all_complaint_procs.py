import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_str = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

candidate_procs = [
    'sp_Task_GetComplaintList',
    'sp_Task_GetComplaintList_html',
    'sp_Task_ComplaintForm',
    'sp_Task_ComplaintForm_html',
    'sp_Task_Complaint_Resolve',
    'sp_Task_Complaint_GetDataList',
    'sp_Task_TaskDetail',
    'sp_Task_getComplaintTypes',
    'sp_Task_Complaint_GetUnfinishedTasks',
    'sp_Task_ComplaintForm_param',
    'sp_Task_Complaint_GetDetail',
    'sp_Task_Complaint_Submit',
]

try:
    conn = pyodbc.connect(conn_str)
    cursor = conn.cursor()
    
    print("=== Checking existence and definitions of procedures ===")
    for proc in candidate_procs:
        cursor.execute("SELECT OBJECT_ID(?, 'P')", proc)
        obj_id = cursor.fetchone()[0]
        if obj_id:
            print(f"[FOUND] {proc}")
        else:
            print(f"[MISSING] {proc}")
            
    conn.close()
except Exception as e:
    print("Error:", e)
