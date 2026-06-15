import json
import sys

with open(r'C:\Users\Huu.Tran\.gemini\antigravity-ide\brain\d058844a-4f75-4b86-a3a2-3b20366c6383\.system_generated\steps\960\output.txt', 'r', encoding='utf-8') as f:
    data = json.load(f)

definition = data['rows'][0][0]
with open(r'C:\Users\Huu.Tran\Downloads\VietinsoftWork\SQL script\sp_KPIListEmailManual_html_responsive.sql', 'w', encoding='utf-8') as f:
    f.write(definition)
print("Saved to sp_KPIListEmailManual_html_responsive.sql")
