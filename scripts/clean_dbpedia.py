#!/usr/bin/env python3
"""
Rewrite problematic RDF datatypes for Virtuoso compatibility.

Why?
-----
Recent versions of Virtuoso appear to have issues handling large quantities of
xsd:integer typed literals (arbitrary-precision) during RDF bulk loading.

This script rewrites:

    "123"^^xsd:integer
        ->
    "123"^^xsd:long

When the value fits within signed 64-bit range. Values outside signed 64-bit range
remain untouched.

Usage
-----
    clean_dbpedia.py INPUT_FILE [-b|--backup]

Example
-------
    clean_dbpedia.py out0.nt --backup
"""

import re
import os
import shutil
import tempfile
import argparse

from tqdm import tqdm


XSD_INTEGER = "http://www.w3.org/2001/XMLSchema#integer"
XSD_LONG = "http://www.w3.org/2001/XMLSchema#long"

INT64_MIN = -9223372036854775808
INT64_MAX = 9223372036854775807


# Matches RDF typed literals safely, including escaped quotes.
#
# Captures:
#   group(1) = literal contents
#   group(2) = datatype URI
#
DTYPE_PATTERN = re.compile(
    r'"((?:[^"\\\\]|\\\\.)*)"\^\^<([^>]+)>'
)


def rewrite_datatypes(line: str) -> str:
    """
    Rewrite xsd:integer -> xsd:long when value fits int64.
    """

    def replacer(match: re.Match) -> str:
        literal = match.group(1)
        datatype = match.group(2)

        if datatype != XSD_INTEGER:
            return match.group(0)

        value = int(literal)

        # Rewrite only when safely representable as xsd:long
        if INT64_MIN <= value <= INT64_MAX:
            return f'"{literal}"^^<{XSD_LONG}>'

        return match.group(0)

    return DTYPE_PATTERN.sub(replacer, line)


def clean(input_file: str, keep_backup: bool = False) -> None:
    """
    Rewrite the file in-place.
    """

    if keep_backup:
        backup_file = input_file + ".bak"
        shutil.copy2(input_file, backup_file)
        print(f"Backup created: {backup_file}")

    dir_name = os.path.dirname(input_file) or "."

    with open(input_file, "r", encoding="utf-8") as f:
        total_lines = sum(1 for _ in f)

    with tempfile.NamedTemporaryFile(
        "w",
        delete=False,
        dir=dir_name,
        encoding="utf-8"
    ) as tmp:

        tmp_name = tmp.name

        with open(input_file, "r", encoding="utf-8") as f:
            for line in tqdm(
                f,
                total=total_lines,
                desc="Rewriting xsd:integer -> xsd:long"
            ):
                tmp.write(rewrite_datatypes(line))

    os.replace(tmp_name, input_file)

    print(f"Finished rewriting: {input_file}")


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Rewrite xsd:integer literals to xsd:long when safe"
    )

    parser.add_argument(
        "input_file",
        help="Path to RDF file"
    )

    parser.add_argument(
        "-b",
        "--backup",
        action="store_true",
        help="Keep backup copy (.bak)"
    )

    args = parser.parse_args()

    clean(args.input_file, args.backup)


if __name__ == "__main__":
    main()