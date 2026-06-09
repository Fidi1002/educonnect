import sys
import os

# Add current directory to path to import convert_bab_4_to_docx
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from convert_bab_4_to_docx import convert_md_to_docx

if __name__ == "__main__":
    md_file = r"d:\apk_edu\apk_edu\test_and_ui_documentation.md"
    docx_file = r"d:\apk_edu\Hasil_Testing_dan_UI_EduConnect.docx"
    
    print(f"Converting {md_file} to {docx_file}...")
    convert_md_to_docx(md_file, docx_file)
    print("Done!")
