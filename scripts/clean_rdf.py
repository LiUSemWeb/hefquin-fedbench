#!/usr/bin/env python3
"""
Clean RDF files in-place:
- Replace spaces inside IRIs with '%20'

Usage:
    clean_jamendo.py INPUT_FILE [-b|--backup]

Example:
    clean_jamendo.py jamendo.rdf --backup
"""
import re
import argparse
import tempfile
import os
import shutil

# Match resource IRI
IRI_PATTERN = re.compile(r'rdf:resource="([^"]*)"')
LANG_PATTERN = re.compile(r'xml:lang="([^"]*)"')


def fix_iri(m):
    iri = m.group(1)
    iri = iri.rstrip()
    iri = iri.replace(" ", "%20")
    iri = iri.replace('"', "%22")
    return f'rdf:resource="{iri}"'


def fix_lang(m):
    lang = m.group(1)
    if lang.startswith("fr_"):
        lang = re.sub(r"([a-z]+).*", r"\1", lang)
    return f'xml:lang="{lang}"'


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
                line = IRI_PATTERN.sub(fix_iri, line)
                line = LANG_PATTERN.sub(fix_lang, line)
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
