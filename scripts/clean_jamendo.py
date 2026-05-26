#!/usr/bin/env python3
"""
Clean malformed RDF/XML files in-place.


Operations:
- Normalize malformed IRIs
- Percent-encode spaces inside IRIs
- Repair common malformed HTTP prefixes
- Convert invalid foaf:homepage IRIs into literal values

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


# Exact malformed URL replacements
HOMEPAGE_FIXES = {
    '  <foaf:homepage rdf:resource="%3A%20En%20construction%20!"/>': '  <foaf:homepage>: En construction !</foaf:homepage>',
    '  <foaf:homepage rdf:resource="http://:-%28%20%C3%A0%20venir"/>': '  <foaf:homepage>http://:-( à venir</foaf:homepage>',
    '  <foaf:homepage rdf:resource="http://"/>': '  <foaf:homepage>http://</foaf:homepage>',
    '  <foaf:homepage rdf:resource="http://---"/>': '  <foaf:homepage>http://---</foaf:homepage>',
    '  <foaf:homepage rdf:resource="perso.wanadoo.fr/spatz/"/>': '  <foaf:homepage>perso.wanadoo.fr/spatz/</foaf:homepage>',
    '  <foaf:homepage rdf:resource="http://pas%20encore%20de%20site%20web"/>': '  <foaf:homepage>http://pas%20encore%20de%20site%20web</foaf:homepage>'
}

IRI_REPLACEMENTS = {
    " ": "%20",
    "http:%5C%5C": "http://",
    "http:%5C": "http://",
    "http:/d": "http://d",
    "http;": "http:",
    "http//:": "http://",
    "http//": "http://"
}

IRI_PATTERN = re.compile(r'<foaf:homepage rdf:resource="([^"]+)"/>')


def fix_iri(m):
    iri = m.group(1).strip()
    
    iri = re.sub(r"^(https?://[^:]+):", "\1%3A", iri)
    iri = re.sub(r"^.%3A//", "", iri)
    iri = re.sub(r"^(%20)+", "", iri)
    iri = iri.replace(" ", "%20")
    iri = iri.replace("http:%5C%5C", "http://")
    iri = iri.replace("http:%5C", "http://")
    iri = iri.replace("http:/d", "http://d")
    iri = iri.replace("http;", "http:")
    iri = iri.replace("http//:", "http://")
    iri = iri.replace("http//", "http://")
    return f'rdf:resource="{iri}"'


def fix_iri(match: re.Match) -> str:
    """Normalize malformed IRIs."""

    iri = match.group(1).strip()

    iri = re.sub(r"^(https?://[^/:]+):", r"\1%3A", iri)
    iri = re.sub(r"^.%3A//", "", iri)
    iri = re.sub(r"^(%20)+", "", iri)

    for old, new in IRI_REPLACEMENTS.items():
        iri = iri.replace(old, new)


    # Invalid homepage values become literals
    if not re.match(r"^https?://", iri):
        return f"<foaf:homepage>{iri}</foaf:homepage>"

    return f'<foaf:homepage rdf:resource="{iri}"/>'


def fix_line(line: str) -> str:
    """Repair exact malformed homepage entries."""

    for old, new in HOMEPAGE_FIXES.items():
        line = line.replace(old, new)

    return line


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
                line = fix_line(line)
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
