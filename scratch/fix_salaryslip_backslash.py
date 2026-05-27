"""Fix backslash-quote pattern: \'' → ''' in salaryslip redesign script."""
path = r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\redesign_MnuPRL445_salaryslip_ParadiseStyle_20260527.sql'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Pattern: \'' in T-SQL produces literal backslash + quote. We want just quote.
# Fix: replace \'' with ''' everywhere
# The pattern appears as: \'' + N' or \')
# After: ''' + N' or ''')

old = "\\''"
new = "'''"
count = content.count(old)
print(f"Found {count} occurrences of \\'' ")
content = content.replace(old, new)
print(f"Replaced {count} occurrences")

# Verify
remaining = content.count("\\''")
print(f"Remaining: {remaining}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

# Now fix the tblDataSetting and tblDataSettingLayout schema issues
# I need to check what columns actually exist. Let me read the script and fix based on DB schema.
print("Backslash fix done. Schema fixes needed for tblDataSetting/tblDataSettingLayout.")
