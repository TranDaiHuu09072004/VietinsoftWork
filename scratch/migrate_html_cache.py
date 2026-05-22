import pyodbc
import sys

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

def get_source_data(conn):
    cursor = conn.cursor()
    # We query specific rows for the leave request
    query = """
    SELECT TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData
    FROM tblHtmlScriptCache
    WHERE TableName IN ('sp_ResignationLeave', 'sp_ResignationLeave_Mobile')
    """
    cursor.execute(query)
    rows = cursor.fetchall()
    columns = [col[0] for col in cursor.description]
    data = []
    for r in rows:
        data.append(dict(zip(columns, r)))
    cursor.close()
    return data

def upsert_destination(conn, row):
    cursor = conn.cursor()
    # Check if row exists in destination
    check_query = """
    SELECT COUNT(*) 
    FROM tblHtmlScriptCache 
    WHERE TableName = ? AND LanguageID = ? AND (ScreenType = ? OR (ScreenType IS NULL AND ? IS NULL))
    """
    cursor.execute(check_query, (row['TableName'], row['LanguageID'], row['ScreenType'], row['ScreenType']))
    exists = cursor.fetchone()[0] > 0

    if exists:
        print(f"Updating existing row: {row['TableName']} ({row['LanguageID']})")
        update_query = """
        UPDATE tblHtmlScriptCache
        SET html = ?, HtmlParadise = ?, paradiseJs = ?, Version = ?, VersionData = ?
        WHERE TableName = ? AND LanguageID = ? AND (ScreenType = ? OR (ScreenType IS NULL AND ? IS NULL))
        """
        cursor.execute(update_query, (
            row['html'], row['HtmlParadise'], row['paradiseJs'], row['Version'], row['VersionData'],
            row['TableName'], row['LanguageID'], row['ScreenType'], row['ScreenType']
        ))
    else:
        print(f"Inserting new row: {row['TableName']} ({row['LanguageID']})")
        insert_query = """
        INSERT INTO tblHtmlScriptCache (TableName, LanguageID, ScreenType, html, HtmlParadise, paradiseJs, Version, VersionData)
        VALUES (?, ?, ?, ?, ?, ?, ?, ?)
        """
        cursor.execute(insert_query, (
            row['TableName'], row['LanguageID'], row['ScreenType'],
            row['html'], row['HtmlParadise'], row['paradiseJs'], row['Version'], row['VersionData']
        ))
    cursor.close()

try:
    print("Fetching source data from Vietinsoft_Pay...")
    source_rows = get_source_data(conn_vietinsoft)
    print(f"Found {len(source_rows)} source rows.")

    # Prepare mapping of source to destination
    # We will write:
    # - sp_ResignationLeave -> sp_ResignationLeave
    # - sp_ResignationLeave -> sp_ResignationLeave_html
    # - sp_ResignationLeave_Mobile -> sp_ResignationLeave_Mobile
    destination_updates = []
    for row in source_rows:
        if row['TableName'] == 'sp_ResignationLeave':
            # Create a clone for sp_ResignationLeave
            row_desktop = row.copy()
            destination_updates.append(row_desktop)

            # Create a clone for sp_ResignationLeave_html
            row_html = row.copy()
            row_html['TableName'] = 'sp_ResignationLeave_html'
            destination_updates.append(row_html)
        elif row['TableName'] == 'sp_ResignationLeave_Mobile':
            row_mobile = row.copy()
            destination_updates.append(row_mobile)

    print(f"Prepared {len(destination_updates)} target rows for Paradise_Dev.")

    # Begin transaction in Paradise_Dev
    conn_paradise.autocommit = False
    
    for row in destination_updates:
        upsert_destination(conn_paradise, row)

    print("Committing transaction...")
    conn_paradise.commit()
    print("Migration completed successfully!")

except Exception as e:
    print("An error occurred. Rolling back changes...", file=sys.stderr)
    try:
        conn_paradise.rollback()
    except Exception as rb_ex:
        print(f"Rollback failed: {rb_ex}", file=sys.stderr)
    raise e

finally:
    conn_vietinsoft.close()
    conn_paradise.close()
