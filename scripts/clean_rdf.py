#!/usr/bin/env python3
"""
Clean RDF/XML files in-place.

Operations:
- Percent-encode invalid characters inside IRIs
- Normalize malformed xml:lang values such as 'fr_179213'

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

from tqdm import tqdm


IRI_PATTERN = re.compile(r'rdf:resource="([^"]*)"')
LANG_PATTERN = re.compile(r'xml:lang="([^"]*)"')


IRI_REPLACEMENTS = {
    " ": "%20",
    '"': "%22"
}


def clean_iri(iri: str) -> str:
    """Clean and percent-encode invalid IRI characters."""
    iri = iri.rstrip()
    
    # IRI replacements
    for old, new in IRI_REPLACEMENTS.items():
        iri = iri.replace(old, new)

    return iri


def fix_lang(match: re.Match) -> str:
    """Normalize malformed xml:lang attributes."""

    lang = match.group(1)

    if lang.startswith("fr_"):
        lang = lang.split("_")[0]

    return f'xml:lang="{lang}"'


def fix_iri(match: re.Match) -> str:
    """Regex callback for cleaning resource IRIs."""

    iri = clean_iri(match.group(1))
    return f'rdf:resource="{iri}"'


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

    # count number of lines
    with open(input_file, "r", encoding="utf-8") as f:
        total_lines = sum(1 for _ in f)

    with tempfile.NamedTemporaryFile("w", delete=False, dir=dir_name, encoding="utf-8") as tmp:
        tmp_name = tmp.name
        with open(input_file, "r", encoding="utf-8") as f:
            for line in tqdm(f, total=total_lines, desc="Cleaning"):
                line = IRI_PATTERN.sub(fix_iri, line)
                line = LANG_PATTERN.sub(fix_lang, line)
                tmp.write(line)
    os.replace(tmp_name, input_file)


def main() -> None:
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
