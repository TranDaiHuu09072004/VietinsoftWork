"""Fix UserID in salaryslip - replace window.UserID || ... with bare UserID."""
path = r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\redesign_MnuPRL445_salaryslip_ParadiseStyle_20260527.sql'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# The problematic pattern: window.UserID || ' + CAST(@LoginID AS NVARCHAR(20)) + N'
# This is a T-SQL concatenation that produces JS: window.UserID || <number>
# ParadiseHR uses bare UserID global, not window.UserID
# Fix: just use UserID directly (same as original sp_SalarySlip)

old = "window.UserID || ' + CAST(@LoginID AS NVARCHAR(20)) + N'"
new = "UserID"

count = content.count(old)
print(f"Found {count} occurrences")

if count > 0:
    content = content.replace(old, new)
    print("Replaced")

remaining = content.count(old)
print(f"Remaining: {remaining}")

# Also verify
for check in ["window.UserID"]:
    c = content.count(check)
    print(f"Occurrences of '{check}': {c}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
