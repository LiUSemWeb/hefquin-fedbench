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

IRI_PATTERN = re.compile(r'rdf:resource="([^"]+)"')


def fix_iri(m):
    iri = m.group(1)
    iri = iri.strip()
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


def fix_line(line):
    line = line.replace('  <foaf:homepage rdf:resource="%3A%20En%20construction%20!"/>',
                        '  <foaf:homepage>: En construction !</foaf:homepage>')
    line = line.replace('  <foaf:homepage rdf:resource="http://:-%28%20%C3%A0%20venir"/>',
                        '  <foaf:homepage>http://:-( à venir</foaf:homepage>')
    line = line.replace('  <foaf:homepage rdf:resource="http://"/>',
                        '  <foaf:homepage>http://</foaf:homepage>')
    line = line.replace('  <foaf:homepage rdf:resource="http://---"/>',
                        '  <foaf:homepage>http://---</foaf:homepage>')
    line = line.replace('  <foaf:homepage rdf:resource="perso.wanadoo.fr/spatz/"/>',
                        '  <foaf:homepage>perso.wanadoo.fr/spatz/</foaf:homepage>')
    line = line.replace('  <foaf:homepage rdf:resource="http://pas%20encore%20de%20site%20web"/>',
                        '  <foaf:homepage>http://pas%20encore%20de%20site%20web</foaf:homepage>')

    line = re.sub(r'<foaf:homepage rdf:resource="(?!https?)([^"]+)"/>',
                  r'<foaf:homepage>\1</foaf:homepage>', line)
    
    # line = line.replace('  <foaf:homepage rdf:resource="www.myspace.com/gluetrax"/>',
    #                     '  <foaf:homepage>www.myspace.com/gluetrax</foaf:homepage>')
    # line = line.replace('  <foaf:homepage rdf:resource="www.dsekt.com"/>',
    #                     '  <foaf:homepage>www.dsekt.com</foaf:homepage>')
    # line = line.replace('  <foaf:homepage rdf:resource="www.fishbonerocket.com"/>',
    #                     '  <foaf:homepage>www.fishbonerocket.com</foaf:homepage>')


    # line = line.replace('  <foaf:homepage rdf:resource="chrysallis.hautetfort.com"/>',
    #                     '  <foaf:homepage>chrysallis.hautetfort.com</foaf:homepage>')
    # line = line.replace('  <foaf:homepage rdf:resource="chrysallis.hautetfort.com"/>',
    #                     '  <foaf:homepage>chrysallis.hautetfort.com</foaf:homepage>')
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
    with tempfile.NamedTemporaryFile("w", delete=False, dir=dir_name, encoding="utf-8") as tmp:
        tmp_name = tmp.name
        with open(input_file, "r", encoding="utf-8") as f:
            for line in f.readlines():
                line = IRI_PATTERN.sub(fix_iri, line)
                line = fix_line(line)
                tmp.write(line)
                
                # line = SPACE_FIRST_IN_IRI.sub(r"\1", line)
                # line = SPACE_IN_IRI.sub(r"\1%20", line)
                # line = SPACE_COLON_SPACE_IN_IRI.sub(r"\1%3A", line)
                # line = ESCAPED_SLASH_IN_IRI.sub(r"\1//", line)
                # line = MISSING_SLASH_IN_IRI.sub(r"\1/\2", line)
                # line = EXTRA_COLON_IN_IRI.sub(r"\1%5C/", line)
                # line = BAD_RESOURCE_1.sub(r"\1dummy/\2", line)
                # tmp.write(line)
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
