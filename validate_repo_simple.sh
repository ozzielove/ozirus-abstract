#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
WARN=0

pass() { echo "PASS  - $1"; PASS=$((PASS+1)); }
fail() { echo "FAIL  - $1"; FAIL=$((FAIL+1)); }
warn() { echo "WARN  - $1"; WARN=$((WARN+1)); }

echo "=== Repository Validation Results ==="
echo

# 1) PDF exists and is a real PDF
if [ -f docs/Ozirus_Dilemma.pdf ] && [ -s docs/Ozirus_Dilemma.pdf ]; then
  mime=$(file -b --mime-type docs/Ozirus_Dilemma.pdf || echo unknown)
  if [[ "$mime" == "application/pdf"* ]]; then
    pass "docs/Ozirus_Dilemma.pdf exists and is a PDF"
  else
    warn "PDF MIME check - Found file, but MIME type is '$mime'"
  fi
  size=$(stat -f %z docs/Ozirus_Dilemma.pdf 2>/dev/null || echo 0)
  if [ "${size:-0}" -lt 10240 ]; then
    warn "PDF size seems small - Size=${size} bytes"
  fi
else
  fail "docs/Ozirus_Dilemma.pdf missing - Put your final PDF there"
fi

# 2) README links to the PDF
if [ -f README.md ]; then
  if grep -q "docs/Ozirus_Dilemma.pdf" README.md; then
    pass "README links to docs/Ozirus_Dilemma.pdf"
  else
    fail "README link missing - Add a link to docs/Ozirus_Dilemma.pdf"
  fi
else
  fail "README.md missing - Create README.md"
fi

# 3) LICENSE-CODE (Apache 2.0)
if [ -f LICENSE-CODE ] && [ -s LICENSE-CODE ]; then
  if grep -qi "Apache License" LICENSE-CODE; then
    pass "LICENSE-CODE looks like Apache 2.0"
  else
    warn "LICENSE-CODE content check - Ensure this is official Apache text"
  fi
else
  fail "LICENSE-CODE missing - Download from apache.org"
fi

# 4) LICENSE-DOCS (CC BY 4.0)
if [ -f LICENSE-DOCS ] && [ -s LICENSE-DOCS ]; then
  if grep -qi "Creative Commons" LICENSE-DOCS && grep -qi "Attribution" LICENSE-DOCS && grep -qi "4.0" LICENSE-DOCS; then
    pass "LICENSE-DOCS looks like CC BY 4.0"
  else
    warn "LICENSE-DOCS content check - Ensure this is official CC BY 4.0 text"
  fi
else
  fail "LICENSE-DOCS missing - Download from creativecommons.org"
fi

# 5) NOTICE explains license split
if [ -f NOTICE ] && [ -s NOTICE ]; then
  if grep -qi "two kinds of content" NOTICE && grep -qi "Apache" NOTICE && grep -qi "Creative Commons" NOTICE; then
    pass "NOTICE explains the code/docs license split"
  else
    warn "NOTICE wording - Make sure it explains Apache for code and CC BY 4.0 for docs"
  fi
else
  fail "NOTICE missing - Add a NOTICE file explaining the two-license split"
fi

# 6) CITATION.cff basic fields
if [ -f CITATION.cff ] && [ -s CITATION.cff ]; then
  base_ok=true
  for key in "cff-version:" "title:" "authors:" "repository-code:"; do
    if ! grep -q "$key" CITATION.cff; then base_ok=false; fi
  done
  if $base_ok; then
    if grep -q "<your-username>" CITATION.cff; then
      warn "CITATION repository-code placeholder - Replace <your-username>"
    else
      pass "CITATION.cff has key fields and repository-code"
    fi
  else
    fail "CITATION.cff missing fields - Ensure it has cff-version, title, authors, repository-code"
  fi
else
  fail "CITATION.cff missing - Create CITATION.cff"
fi

# 7) Git remote (optional)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git config --get remote.origin.url >/dev/null; then
    pass "Git remote is set"
  else
    warn "No git remote - Set one with: git remote add origin"
  fi
else
  warn "Not a git repo - Run 'git init' if needed"
fi

# 8) src/Ozirus_Dilemma.tex (optional)
if [ -f src/Ozirus_Dilemma.tex ]; then
  pass "Found src/Ozirus_Dilemma.tex (optional)"
else
  warn "No LaTeX source found (optional)"
fi

echo
echo "=== SUMMARY ==="
echo "PASS: $PASS"
echo "FAIL: $FAIL"
echo "WARN: $WARN"
echo

if [ "$FAIL" -gt 0 ]; then
  echo "Result: FAIL ($FAIL blocker issue(s))"
  exit 1
else
  echo "Result: OK (no blockers). Warnings: $WARN"
  exit 0
fi
