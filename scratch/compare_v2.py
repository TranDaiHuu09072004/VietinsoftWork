"""Compare JS from original sp_SalarySlip vs redesign."""
import json, re, sys

# Load original from MCP output
orig_path = r'C:\Users\cuong.vu\.claude\projects\d--VTS-User-Cuong-vu-Agent-work-VietinsoftWork\3087f0c1-9fe3-44a4-af2a-a0ac7ad1ecd0\tool-results\call_00_nBjVWhYm5FqhyAih3pMc6747.json'
with open(orig_path, 'r', encoding='utf-8') as f:
    data = json.load(f)

orig_source = data[0]['text']
orig_json = json.loads(orig_source)
orig_def = orig_json['rows'][0][0]

# Extract JavaScript from original
s1 = orig_def.find('<script>')
s2 = orig_def.find('</script>')
orig_js = orig_def[s1+8:s2]
print(f"=== ORIGINAL JS: {len(orig_js)} chars ===")

# Extract JavaScript from redesign (the SET @html = N'...' part)
redesign_path = r'd:\VTS User\Cuong.vu\Agent work\VietinsoftWork\SQL script\redesign_MnuPRL445_salaryslip_ParadiseStyle_20260527.sql'
with open(redesign_path, 'r', encoding='utf-8') as f:
    redesign = f.read()

# Find the JS section in redesign (look for (function(){ pattern)
js_start = redesign.find("(function(){")
js_end = redesign.find("})();", js_start)
if js_end > 0:
    js_end = redesign.find("</script>", js_end)
redesign_js = redesign[js_start:js_end] if js_end > 0 else ""
print(f"=== REDESIGN JS: {len(redesign_js)} chars ===")

# 1. Compare initial load: document.ready vs IIFE
print("\n--- document.ready pattern ---")
print(f"Original has $(document).ready: {'$(document).ready' in orig_js}")
print(f"Redesign has $(document).ready: {'$(document).ready' in redesign_js}")
print(f"Original wraps all in ready: {orig_js.strip().startswith('$(document).ready')}")

# 2. Compare API call params
print("\n--- API param patterns ---")
import re
orig_params = re.findall(r'param:\s*\[([^\]]+)\]', orig_js)
for i, p in enumerate(orig_params):
    print(f"  Original #{i}: [{p[:150]}]")

print()
redesign_params = re.findall(r'param:\s*\[([^\]]+)\]', redesign_js)
for i, p in enumerate(redesign_params):
    print(f"  Redesign #{i}: [{p[:150]}]")

# 3. Check for UserID patterns
print("\n--- UserID references ---")
print(f"Original 'UserID' count: {orig_js.count('UserID')}")
print(f"Redesign 'UserID' count: {redesign_js.count('UserID')}")

# 4. Compare DOM ID references (first 30 from each)
orig_ids = re.findall(r'\$\("#([^"]+)"\)', orig_js)
redesign_ids = re.findall(r'\$\("#([^"]+)"\)', redesign_js)

print(f"\n--- DOM IDs in original ({len(orig_ids)}): first 25 ---")
for id_ in orig_ids[:25]:
    print(f"  #{id_}")

print(f"\n--- DOM IDs in redesign ({len(redesign_ids)}): first 25 ---")
for id_ in redesign_ids[:25]:
    print(f"  #{id_}")

# 5. Compare HTML element IDs
orig_html_ids = re.findall(r'id="([^"]+)"', orig_def[s1:])
redesign_html_ids = re.findall(r'id="([^"]+)"', redesign_js)

print(f"\n--- HTML IDs in original JS section ({len(orig_html_ids)}): first 20 ---")
for id_ in orig_html_ids[:20]:
    print(f"  #{id_}")

# 6. Check if JS IDs match HTML IDs in redesign
js_set = set(redesign_ids)
html_set = set(redesign_html_ids)
mismatch_js = js_set - html_set
mismatch_html = html_set - js_set
if mismatch_js:
    print(f"\n!!! JS references IDs NOT in HTML: {mismatch_js}")
if mismatch_html:
    print(f"!!! HTML has IDs NOT referenced in JS: {mismatch_html}")
if not mismatch_js and not mismatch_html:
    print(f"\nAll JS-referenced IDs match HTML IDs.")

# 7. Check the overall structure
print("\n--- Structure comparison ---")
print(f"Original JS first 200 chars:")
print(orig_js[:200])
print(f"\nRedesign JS first 200 chars:")
print(redesign_js[:200])
