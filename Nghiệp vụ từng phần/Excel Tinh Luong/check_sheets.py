import pandas as pd
import sys
import io

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8')

def print_sheet(file_path, sheet_name):
    print(f"\n--- {sheet_name} ---")
    try:
        df = pd.read_excel(file_path, sheet_name=sheet_name)
        df = df.fillna("")
        for _, row in df.iterrows():
            if any(val != "" for val in row.values):
                print(row.to_dict())
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    for sheet in ['Sheet2', 'Sheet4', 'tblSalaryHistory']:
        print_sheet("Tinh luong.xlsx", sheet)
