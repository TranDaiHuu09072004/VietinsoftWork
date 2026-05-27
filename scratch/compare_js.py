"""Extract and compare JS from original vs redesign salaryslip."""
import json, re

# Load original from MCP output file
orig_path = r'C:\Users\cuong.vu\.claude\projects\d--VTS-User-Cuong-vu-Agent-work-VietinsoftWork\3087f0c1-9fe3-44a4-af2a-a0ac7ad1ecd0\tool-results\call_00_nBjVWhYm5FqhyAih3pMc6747.json'
with open(orig_path, 'r') as f:
    data = json.load(f)
    orig_source = data[0]['text']
    orig_json = json.loads(orig_source)
    orig_def = orig_json['rows'][0][0]

# Save original source
out_path = r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\scratch\original_sp_SalarySlip.txt'
with open(out_path, 'w', encoding='utf-8') as f:
    f.write(orig_def)
print(f"Saved original source to {out_path}")
print(f"Original source length: {len(orig_def)} chars")

# Load redesign
redesign_path = r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\redesign_MnuPRL445_salaryslip_ParadiseStyle_20260527.sql'
with open(redesign_path, 'r', encoding='utf-8') as f:
    redesign = f.read()

# Extract the JavaScript section from original
# Find <script> tag
script_start = orig_def.find('<script>')
script_end = orig_def.find('</script>')
if script_start >= 0:
    orig_js = orig_def[script_start+8:script_end]
    print(f"\nOriginal JS length: {len(orig_js)} chars")
    # Print first 500 chars
    print("=== Original JS (first 500 chars) ===")
    print(orig_js[:500])

# Find key differences
# 1. Check document.ready structure
print("\n=== document.ready in original ===")
idx = orig_js.find('document').strip()
if idx >= 0:
    print(f"Found 'document' at offset {idx}")

# 2. Compare initial API calls
print("\n=== Original initial API call params ===")
# Find param: ["LoginID"
idx = orig_js.find('"LoginID"')
while idx >= 0:
    context = orig_js[idx:idx+120]
    print(f"  {context}")
    idx = orig_js.find('"LoginID"', idx+1)

# 3. Check specific DOM IDs being set
print("\n=== Original DOM IDs being SET (first 20) ===")
ids = re.findall(r'\$\("#([^"]+)"\)\.text\(', orig_js)
for i, id_ in enumerate(ids[:20]):
    print(f"  {i+1}. #{id_}")
print(f"  Total: {len(ids)} IDs")
