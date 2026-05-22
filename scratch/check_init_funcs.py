import re

files = [
    "scratch/paradise_sp_ResignationLeave_html_EN.html",
    "scratch/paradise_sp_ResignationLeave_html_VN.html",
    "scratch/paradise_sp_ResignationLeave_Mobile_EN.html",
    "scratch/paradise_sp_ResignationLeave_Mobile_VN.html",
]

for fn in files:
    with open(fn, 'r', encoding='utf-8') as f:
        content = f.read()
    init_funcs = re.findall(r'initsp_\w+', content)
    print(f"File: {fn}")
    print(f"  Found init functions: {list(set(init_funcs))}")
