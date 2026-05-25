import subprocess
import os

html_file = "d:\\VTS User\\Cuong.vu\\Agent work\\VietinsoftWork\\scratch\\output.html"
js_file = "d:\\VTS User\\Cuong.vu\\Agent work\\VietinsoftWork\\scratch\\temp.js"

with open(html_file, "r", encoding="utf-8") as f:
    content = f.read()

start_idx = content.find("<script>")
end_idx = content.find("</script>")

if start_idx != -1 and end_idx != -1:
    js_content = content[start_idx + len("<script>"):end_idx]
    with open(js_file, "w", encoding="utf-8") as f:
        f.write(js_content)
    
    print("JS extracted. Running node syntax check...")
    res = subprocess.run(["node", "-c", js_file], capture_output=True, text=True)
    if res.returncode == 0:
        print("JavaScript syntax is VALID!")
    else:
        print("JavaScript syntax ERROR:")
        print(res.stderr)
else:
    print("No script block found.")
