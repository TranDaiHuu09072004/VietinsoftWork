import pyodbc
import sys

sys.stdout.reconfigure(encoding='utf-8')

conn_base = (
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "DATABASE=Paradise_Dev;"
    "TrustServerCertificate=yes;"
)

try:
    conn = pyodbc.connect(conn_base)
    cursor = conn.cursor()
    
    # Get proc def
    cursor.execute("SELECT OBJECT_DEFINITION(OBJECT_ID('sp_Task_TaskList_html'))")
    proc_def = cursor.fetchone()[0]
    
    # Get cache html
    cursor.execute("SELECT html FROM tblHtmlScriptCache WHERE TableName = 'sp_Task_TaskList' AND LanguageID = 'VN'")
    cache_html = cursor.fetchone()[0]
    
    print(f"Proc Def Length: {len(proc_def)}")
    print(f"Cache HTML Length: {len(cache_html)}")
    
    # Let's see what the first 1000 chars of the cache HTML are
    print("\n--- FIRST 500 CHARS OF CACHE HTML ---")
    print(cache_html[:500])
    
    # Let's check if the proc_def is a substring of cache_html
    # We will search for a unique segment of the proc_def in cache_html
    # In sp_Task_TaskList_html, let's search for a string like "fullcalendar" or "switcher-container"
    search_str = "switcher-container"
    pos_in_proc = proc_def.find(search_str)
    pos_in_cache = cache_html.find(search_str)
    print(f"\nPosition of '{search_str}' in Proc Def: {pos_in_proc}")
    print(f"Position of '{search_str}' in Cache HTML: {pos_in_cache}")
    
    # Let's check where the cache HTML differs or what is prepended/appended
    # Usually cache_html has a header prepended, or the procedure returns multiple pieces of HTML.
    # Wait, does the procedure sp_Task_TaskList_html return HTML via SELECT @html?
    # Yes! Let's check how sp_GenerateHTMLScript executes. It executes the procedure to get the HTML!
    # Ah! When it executes the procedure, the procedure itself returns the HTML.
    # So the HTML is not static in the procedure definition; the procedure constructs it and returns it via SELECT!
    # So the definition of the procedure contains the T-SQL code that returns the HTML, and the HTML is SELECTed.
    # Therefore, the T-SQL code contains string literals, and when executed, it returns the HTML string.
    # That explains why the cache HTML is different!
    # Wait! If the procedure definition contains string literals, then the string literals in the definition must contain the HTML!
    # If the HTML in the cache contains "fa-solid fa-chevron-down", then the procedure definition MUST contain that string literal too, UNLESS it is dynamically built, OR it is appended by sp_GenerateHTMLScript!
    
    conn.close()
except Exception as e:
    print("Error:", e)
