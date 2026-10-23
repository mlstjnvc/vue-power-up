#!/usr/bin/env python3
"""Check that every **Source:** URL in the rule references resolves (HTTP < 400).

Anchors (#fragment) are not verified, only the page. Needs network access.

Usage: python3 tests/check_links.py
"""
import pathlib
import re
import sys
import urllib.error
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parent.parent
REFS = ROOT / "skills" / "vue-power-up" / "references"
URL = re.compile(r"https://[^\s)`'\"<>·]+")


def main():
    urls = {}
    for path in sorted(REFS.glob("*.md")):
        for n, line in enumerate(path.read_text(encoding="utf-8").splitlines(), 1):
            if line.startswith("**Source:**"):
                for u in URL.findall(line):
                    urls.setdefault(u.split("#")[0].rstrip(".,"), f"{path.name}:{n}")
    bad = []
    for page, where in sorted(urls.items()):
        req = urllib.request.Request(page, headers={"User-Agent": "vue-power-up-linkcheck"})
        try:
            with urllib.request.urlopen(req, timeout=20) as resp:
                status = resp.status
        except urllib.error.HTTPError as e:
            status = e.code
        except Exception as e:  # network errors
            status = f"ERR {type(e).__name__}"
        if not (isinstance(status, int) and status < 400):
            bad.append(f"{status}  {page}  ({where})")
    if bad:
        print("\n".join(bad))
        print(f"\nFAIL: {len(bad)} of {len(urls)} source pages did not resolve")
        return 1
    print(f"OK: {len(urls)} source pages resolve")
    return 0


if __name__ == "__main__":
    sys.exit(main())
