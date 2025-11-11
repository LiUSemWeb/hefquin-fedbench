#!/usr/bin/env python3
"""
Clean N3 files in-place:
- Replace spaces inside IRIs with '%20'
- Replace literal backslash with '\n' for lines that do not end with a period.
- Escape colon trailing first slash.

Usage:
    clean_n3.py INPUT_FILE [-b|--backup]

Example:
    clean_n3.py chebi.n3 --backup
"""
import re
import argparse
import tempfile
import os
import shutil

# Match a single space that is inside <...>
IRI_PATTERN = re.compile(r'<([^>\r\n]*)>')
NON_PORT_COLON_IN_IRI = re.compile(r"(<https?://[^>]*?/[^>]*?):(?=[^>]*>)")


def fix_iri(m):
    iri = m.group(1)
    iri = iri.replace("", "%20") # <control> character
    iri = iri.replace(" ", "%20")
    iri = iri.replace('"', "%22")
    iri = iri.replace("}", "%7D")
    iri = iri.replace("`", "%60")
    while NON_PORT_COLON_IN_IRI.search(iri):
        iri = NON_PORT_COLON_IN_IRI.sub(r"\1%3A", iri)
    return f"<{iri}>"


def clean(input_file: str, keep_backup: bool = False) -> None:
    """
    Clean the file in-place by writing to a temp file, then replacing original.
    Optionally keep a backup.
    """
    if keep_backup:
        backup_file = input_file + ".bak"
        shutil.copy2(input_file, backup_file)
        print(f"Backup created: {backup_file}")
    
    dir_name = os.path.dirname(input_file) or "."
    with tempfile.NamedTemporaryFile("w", delete=False, dir=dir_name, encoding="utf-8") as tmp:
        tmp_name = tmp.name
        with open(input_file, "r", encoding="utf-8") as f:
            for line in f.readlines():
                stripped = line.rstrip()
                if stripped and not stripped.endswith("."):
                    line = stripped + "\\n"
                line = IRI_PATTERN.sub(fix_iri, line)
                tmp.write(line)
    os.replace(tmp_name, input_file)


def main():
    parser = argparse.ArgumentParser(description="Clean N3 files")
    parser.add_argument("input_file", help="Path to the input N3 file")
    parser.add_argument(
        "-b", "--backup",
        action="store_true",
        help="Keep a backup copy (.bak) before modifying"
    )
    args = parser.parse_args()

    clean(args.input_file, args.backup)


if __name__ == "__main__":
    main()
