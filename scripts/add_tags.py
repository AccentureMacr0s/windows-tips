#!/usr/bin/env python3
"""
add_tags.py
Builds and validates a GIPHY-compliant tag list for a GIF, including
Cyrillic and transliterated Latin variants for Cyrillic search terms.

Usage:
    python scripts/add_tags.py [options]

Options:
    --tags    TAGS   Comma-separated list of base tags (Latin or Cyrillic)
    --output  PATH   Write the final tag list to this file (default: tags.txt)
    --print          Print the final tag list to stdout

GIPHY tag requirements (enforced by this script):
    - Maximum 10 tags per GIF.
    - Each tag: 1–30 characters, alphanumeric + spaces/underscores/hyphens.
    - Cyrillic tags are preserved as-is; a Latin transliteration is also added.

Examples:
    python scripts/add_tags.py --tags "юрий клинский,gif,funny" --print
    python scripts/add_tags.py --tags "animation,loop" --output tags.txt

Environment variables (alternative to --tags):
    GIF_TAGS   Comma-separated tags (same format as --tags)
"""

import argparse
import os
import re
import sys


# ---------------------------------------------------------------------------
# Constants
# ---------------------------------------------------------------------------

MAX_TAGS      = 10
MAX_TAG_LEN   = 30
TAG_PATTERN   = re.compile(r'^[\w\s\-]+$', re.UNICODE)

# Simple Cyrillic → Latin transliteration table (GOST 7.79-2000 / common web)
TRANSLIT_MAP = {
    'а': 'a',  'б': 'b',  'в': 'v',  'г': 'g',  'д': 'd',
    'е': 'e',  'ё': 'yo', 'ж': 'zh', 'з': 'z',  'и': 'i',
    'й': 'j',  'к': 'k',  'л': 'l',  'м': 'm',  'н': 'n',
    'о': 'o',  'п': 'p',  'р': 'r',  'с': 's',  'т': 't',
    'у': 'u',  'ф': 'f',  'х': 'kh', 'ц': 'ts', 'ч': 'ch',
    'ш': 'sh', 'щ': 'shch','ъ': '',  'ы': 'y',  'ь': '',
    'э': 'e',  'ю': 'yu', 'я': 'ya',
}


# ---------------------------------------------------------------------------
# Tag utilities
# ---------------------------------------------------------------------------

def is_cyrillic(text: str) -> bool:
    """Return True if the string contains at least one Cyrillic character."""
    return bool(re.search(r'[\u0400-\u04FF]', text))


def transliterate(text: str) -> str:
    """Convert a Cyrillic string to a Latin transliteration."""
    result = []
    for ch in text.lower():
        result.append(TRANSLIT_MAP.get(ch, ch))
    return ''.join(result)


def normalize_tag(tag: str) -> str:
    """Strip leading/trailing whitespace and collapse internal spaces."""
    return re.sub(r'\s+', ' ', tag.strip())


def validate_tag(tag: str) -> tuple:
    """
    Return (is_valid: bool, reason: str).
    An empty reason means the tag is valid.
    """
    if not tag:
        return False, 'empty tag'
    if len(tag) > MAX_TAG_LEN:
        return False, f'exceeds {MAX_TAG_LEN} characters ({len(tag)})'
    if not TAG_PATTERN.match(tag):
        return False, f'contains disallowed characters: {tag!r}'
    return True, ''


def expand_tags(raw_tags: list) -> list:
    """
    Normalize, validate, and expand a raw tag list:
      - Normalize whitespace.
      - Validate each tag.
      - For Cyrillic tags, add a Latin transliteration sibling.
      - Deduplicate while preserving order.
      - Truncate to MAX_TAGS.
    """
    seen   = []
    errors = []

    for raw in raw_tags:
        tag = normalize_tag(raw)
        ok, reason = validate_tag(tag)
        if not ok:
            errors.append(f'  Skipping tag {raw!r}: {reason}')
            continue

        if tag not in seen:
            seen.append(tag)

        # Add Latin transliteration for Cyrillic tags
        if is_cyrillic(tag):
            latin = normalize_tag(transliterate(tag))
            ok2, _ = validate_tag(latin)
            if ok2 and latin not in seen:
                seen.append(latin)

    if errors:
        print('[add_tags] Warnings:')
        for e in errors:
            print(e)

    if len(seen) > MAX_TAGS:
        print(
            f'[add_tags] Tag list truncated from {len(seen)} to {MAX_TAGS} '
            f'(GIPHY maximum).'
        )
        seen = seen[:MAX_TAGS]

    return seen


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def parse_args():
    parser = argparse.ArgumentParser(
        description='Build a GIPHY-compliant tag list with Cyrillic support.'
    )
    parser.add_argument(
        '--tags',
        default=os.environ.get('GIF_TAGS', ''),
        help='Comma-separated tags (Latin or Cyrillic)',
    )
    parser.add_argument(
        '--output',
        default='tags.txt',
        help='File to write the final tag list to',
    )
    parser.add_argument(
        '--print',
        action='store_true',
        dest='print_tags',
        help='Print the final tag list to stdout',
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if not args.tags:
        sys.exit(
            'ERROR: No tags provided. Use --tags "tag1,tag2" or set GIF_TAGS.'
        )

    raw_tags = [t for t in args.tags.split(',') if t.strip()]
    final    = expand_tags(raw_tags)

    if not final:
        sys.exit('ERROR: No valid tags after processing.')

    tag_string = ','.join(final)

    # Write to file
    with open(args.output, 'w', encoding='utf-8') as fh:
        fh.write(tag_string + '\n')
    print(f'[add_tags] Tags written to {args.output}: {tag_string}')

    # Write to GitHub Actions step output if available
    github_output = os.environ.get('GITHUB_OUTPUT', '')
    if github_output:
        with open(github_output, 'a', encoding='utf-8') as fh:
            fh.write(f'gif_tags={tag_string}\n')

    if args.print_tags:
        print(tag_string)


if __name__ == '__main__':
    main()
