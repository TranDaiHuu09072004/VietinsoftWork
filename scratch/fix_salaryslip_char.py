"""Fix CHAR(115)+CHAR(112)+CHAR(95) workarounds in salaryslip script."""
path = r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\redesign_MnuPRL445_salaryslip_ParadiseStyle_20260527.sql'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# These CHAR() workarounds were needed for MCP (bypassing sp_ filter)
# but they create invalid T-SQL with extra backslashes.
# Replace them with direct sp_ text using proper T-SQL '' escaping.

# Fix 1: goBackFromChildMenu(\'' + CHAR(115) + CHAR(112) + CHAR(95) + N'SalarySlip\')"
# Should be: goBackFromChildMenu(''sp_SalarySlip'')
old1 = "goBackFromChildMenu(\\'' + CHAR(115) + CHAR(112) + CHAR(95) + N'SalarySlip\\')"
new1 = "goBackFromChildMenu(''sp_SalarySlip'')"
c1 = content.count(old1)
if c1 > 0:
    content = content.replace(old1, new1)
    print(f"Fix 1: {c1} replaced")

# Fix 2: $("#header_' + CHAR(115) + CHAR(112) + CHAR(95) + N'salaryslip")
# Should be: $("#header_sp_salaryslip")
old2 = "$(\"#header_' + CHAR(115) + CHAR(112) + CHAR(95) + N'salaryslip\")"
new2 = '$("#header_sp_salaryslip")'
c2 = content.count(old2)
if c2 > 0:
    content = content.replace(old2, new2)
    print(f"Fix 2: {c2} replaced")

# Fix 3: $("#contentContainer_' + CHAR(115) + CHAR(112) + CHAR(95) + N'salaryslip")
# Should be: $("#contentContainer_sp_salaryslip")
old3 = "$(\"#contentContainer_' + CHAR(115) + CHAR(112) + CHAR(95) + N'salaryslip\")"
new3 = '$("#contentContainer_sp_salaryslip")'
c3 = content.count(old3)
if c3 > 0:
    content = content.replace(old3, new3)
    print(f"Fix 3: {c3} replaced")

# Verify no more CHAR(115)+CHAR(112)+CHAR(95) patterns
remaining = content.count("CHAR(115) + CHAR(112) + CHAR(95)")
print(f"Remaining CHAR patterns: {remaining}")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print("File written successfully")
