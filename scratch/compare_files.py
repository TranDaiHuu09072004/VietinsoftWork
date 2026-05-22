import difflib

def compare_files(f1, f2):
    with open(f1, 'r', encoding='utf-8') as file1:
        lines1 = file1.readlines()
    with open(f2, 'r', encoding='utf-8') as file2:
        lines2 = file2.readlines()
    
    diff = list(difflib.unified_diff(lines1, lines2, fromfile=f1, tofile=f2, n=1))
    if not diff:
        print(f"Files {f1} and {f2} are identical.")
    else:
        print(f"Differences found between {f1} and {f2}:")
        # Print first 20 lines of difference
        for line in diff[:20]:
            print(line, end='')
        if len(diff) > 20:
            print(f"\n... (and {len(diff) - 20} more lines)")

print("=== Comparing English files ===")
compare_files("scratch/vietinsoft_sp_ResignationLeave_EN.html", "scratch/vietinsoft_sp_ResignationLeave_Mobile_EN.html")

print("\n=== Comparing Vietnamese files ===")
compare_files("scratch/vietinsoft_sp_ResignationLeave_VN.html", "scratch/vietinsoft_sp_ResignationLeave_Mobile_VN.html")
