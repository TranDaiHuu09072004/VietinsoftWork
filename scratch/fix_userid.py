"""Fix UserID references in salaryslip ParadiseStyle script.

Issue: window.UserID doesn't work in ParadiseHR because UserID is
a bare global variable (var UserID), not always on window.
Fix: Use a local _uid variable with typeof check, matching original pattern.
"""
path = r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\redesign_MnuPRL445_salaryslip_ParadiseStyle_20260527.sql'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the problematic UserID pattern
old = "window.UserID || ' + CAST(@LoginID AS NVARCHAR(20)) + N'"
new = "\" + ((typeof UserID !== \"undefined\") ? UserID : '" + CAST(@LoginID AS NVARCHAR(20)) + N"') + \""

# Actually, this pattern is embedded in T-SQL string concatenation, not N'...' blocks.
# Let me find the exact patterns.
# The pattern is: "window.UserID || ' + CAST(@LoginID AS NVARCHAR(20)) + N'"
# Which in JS produces: window.UserID || <number>
#
# We want: (typeof UserID !== "undefined") ? UserID : <number>

count = content.count(old)
print(f"Found {count} occurrences of window.UserID pattern")

# Replace with a variable-based approach
# First, add a uid variable definition at the top of the IIFE
# Find: (function(){
# Add after: var _uid = (typeof UserID !== "undefined") ? UserID : @LoginID;

uid_decl = "\" + ((typeof UserID !== \"undefined\") ? UserID : '" + CAST(@LoginID AS NVARCHAR(20)) + N"') + \""

content = content.replace(old, uid_decl)
print(f"Replaced {count} occurrences")

# Verify
remaining = content.count("window.UserID")
print(f"Remaining window.UserID: {remaining}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
