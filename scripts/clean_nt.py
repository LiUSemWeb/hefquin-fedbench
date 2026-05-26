#!/usr/bin/env python3
"""
Clean N3 files in-place:
- Percent-encode invalid characters inside IRIs enclosed in <...>
- Replace malformed control characters inside IRIs
- Append the literal sequence '\\n' to lines not ending with '.'
- Escape colons appearing in the path portion of IRIs

Usage:
    clean.py INPUT_FILE [-b|--backup]

Example:
    clean_nt.py chebi.n3 --backup
"""
import re
import argparse
import tempfile
import os
import shutil

from tqdm import tqdm

IRI_PATTERN = re.compile(r'<([^>\r\n]*)>')

# Matches ':' occurring after the hostname part and optional port
NON_PORT_COLON_IN_IRI = re.compile(r"(<https?://[^>]*?/[^>]*?):(?=[^>]*>)")


IRI_REPLACEMENTS = {
    "": "%20", # <control> character
    " ": "%20",
    '"': "%22",
    "}": "%7D",
    "`": "%60"
}

def clean_iri(iri: str) -> str:
    """Apply percent-encoding fixes to an IRI."""

    # IRI replacements
    for old, new in IRI_REPLACEMENTS.items():
        iri = iri.replace(old, new)

    # Escape colons in path segments
    while NON_PORT_COLON_IN_IRI.search(iri):
        iri = NON_PORT_COLON_IN_IRI.sub(r"\1%3A", iri)

    return iri


def fix_iri(match: re.Match) -> str:
    """Regex callback for cleaning IRIs inside <...>."""
    iri = match.group(1)
    return f"<{clean_iri(iri)}>"


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
                stripped = line.rstrip()

                if stripped and not stripped.endswith("."):
                    line = stripped + "\\n"

                cleaned = IRI_PATTERN.sub(fix_iri, line)
                tmp.write(cleaned)

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
