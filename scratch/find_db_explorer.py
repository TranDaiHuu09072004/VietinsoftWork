import os

start_dir = r"d:\VTS User\Cuong.vu\Agent work\VietinsoftWork"
found = []

for root, dirs, files in os.walk(start_dir):
    if "db_explorer.py" in files:
        found.append(os.path.join(root, "db_explorer.py"))

print("Found paths:")
for p in found:
    print(p)
