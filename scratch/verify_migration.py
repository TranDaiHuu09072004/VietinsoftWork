import pyodbc
import sys
import hashlib

sys.stdout.reconfigure(encoding='utf-8')

# Connection details for Vietinsoft_Pay
conn_vietinsoft = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,6688;"
    "DATABASE=Vietinsoft_Pay;"
    "UID=ai.sa;"
    "PWD=ThoiDaiVibeCodeIA@2026;"
    "TrustServerCertificate=yes;"
)

# Connection details for Paradise_Dev
conn_paradise = pyodbc.connect(
    "DRIVER={ODBC Driver 17 for SQL Server};"
    "SERVER=192.168.11.51,2222;"
    "DATABASE=Paradise_Dev;"
    "UID=vts.sa;"
    "PWD=LuaThieng1@3@2020;"
    "TrustServerCertificate=yes;"
)

def get_row_hash(row):
    # Calculate a hash of the content fields (html, HtmlParadise, paradiseJs, Version, VersionData)
    # We convert None to empty string
    h = hashlib.sha256()
    h.update((row.html or "").encode('utf-8'))
    h.update((row.HtmlParadise or "").encode('utf-8'))
    h.update((row.paradiseJs or "").encode('utf-8'))
    h.update((row.Version or "").encode('utf-8'))
    h.update((row.VersionData or "").encode('utf-8'))
    return h.hexdigest()

def get_db_rows(conn):
    cursor = conn.cursor()
    cursor.execute("""
        SELECT TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData
        FROM tblHtmlScriptCache
        WHERE TableName LIKE '%ResignationLeave%'
    """)
    rows = cursor.fetchall()
    cursor.close()
    return rows

print("Reading rows from Vietinsoft_Pay...")
v_rows = get_db_rows(conn_vietinsoft)
v_map = {}
for r in v_rows:
    key = (r.TableName, r.LanguageID)
    v_map[key] = {
        'html_len': len(r.html) if r.html else 0,
        'hash': get_row_hash(r),
        'version': r.Version
    }
    print(f"  Vietinsoft: {key[0]} ({key[1]}) - Len: {v_map[key]['html_len']}, Hash: {v_map[key]['hash'][:10]}, Version: {r.Version}")

print("\nReading rows from Paradise_Dev...")
p_rows = get_db_rows(conn_paradise)
p_map = {}
for r in p_rows:
    key = (r.TableName, r.LanguageID)
    p_map[key] = {
        'html_len': len(r.html) if r.html else 0,
        'hash': get_row_hash(r),
        'version': r.Version
    }
    print(f"  Paradise: {key[0]} ({key[1]}) - Len: {p_map[key]['html_len']}, Hash: {p_map[key]['hash'][:10]}, Version: {r.Version}")

print("\n=== Cross Verification ===")
errors = 0

# Check sp_ResignationLeave
for lang in ['EN', 'VN']:
    v_key = ('sp_ResignationLeave', lang)
    # in Paradise it should exist as sp_ResignationLeave and sp_ResignationLeave_html
    p_keys = [('sp_ResignationLeave', lang), ('sp_ResignationLeave_html', lang)]
    
    if v_key not in v_map:
        print(f"ERROR: Source row {v_key} is missing in Vietinsoft_Pay.")
        errors += 1
        continue
        
    for p_key in p_keys:
        if p_key not in p_map:
            print(f"ERROR: Destination row {p_key} is missing in Paradise_Dev.")
            errors += 1
            continue
        
        # compare len and hash
        if v_map[v_key]['html_len'] != p_map[p_key]['html_len']:
            print(f"ERROR: Length mismatch for {p_key}. Source: {v_map[v_key]['html_len']}, Dest: {p_map[p_key]['html_len']}")
            errors += 1
        elif v_map[v_key]['hash'] != p_map[p_key]['hash']:
            print(f"ERROR: Hash mismatch for {p_key}. Content is different.")
            errors += 1
        else:
            print(f"SUCCESS: {p_key} matches source {v_key} perfectly.")

# Check sp_ResignationLeave_Mobile
for lang in ['EN', 'VN']:
    v_key = ('sp_ResignationLeave_Mobile', lang)
    p_key = ('sp_ResignationLeave_Mobile', lang)
    
    if v_key not in v_map:
        print(f"ERROR: Source row {v_key} is missing in Vietinsoft_Pay.")
        errors += 1
        continue
        
    if p_key not in p_map:
        print(f"ERROR: Destination row {p_key} is missing in Paradise_Dev.")
        errors += 1
        continue
        
    # compare len and hash
    if v_map[v_key]['html_len'] != p_map[p_key]['html_len']:
        print(f"ERROR: Length mismatch for {p_key}. Source: {v_map[v_key]['html_len']}, Dest: {p_map[p_key]['html_len']}")
        errors += 1
    elif v_map[v_key]['hash'] != p_map[p_key]['hash']:
        print(f"ERROR: Hash mismatch for {p_key}. Content is different.")
        errors += 1
    else:
        print(f"SUCCESS: {p_key} matches source {v_key} perfectly.")

if errors == 0:
    print("\nALL CHECKS PASSED! Migration is 100% verified.")
else:
    print(f"\nCOMPLETED WITH {errors} ERRORS.")

conn_vietinsoft.close()
conn_paradise.close()
