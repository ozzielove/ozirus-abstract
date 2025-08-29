#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
WARN=0
TMP="repo_smoke_report.json.tmp"
FIRST=1

start_report() {
  echo '{"tests": [' > "$TMP"
}

finish_report() {
  echo '], "summary": {"pass": '"$PASS"', "fail": '"$FAIL"', "warn": '"$WARN"'}, "ok": '"$(["$FAIL" -eq 0 ] && echo true || echo false)"', "timestamp": '"\"$(date -u +%FT%TZ)\""' }' >> "$TMP"
  mv "$TMP" repo_smoke_report.json
}

record() {
  local name="$1"; shift
  local status="$1"; shift
  local severity="$1"; shift
  local note="$1"; shift
  if [ $FIRST -eq 0 ]; then echo ',' >> "$TMP"; fi
  FIRST=0
  note_escaped=$(printf '%s' "$note" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/
/; s/
/\
/g')
  printf '  {"name":"%s","status":"%s","severity":"%s","note":"%s"}' "$name" "$status" "$severity" "$note_escaped" >> "$TMP"
}

pass()  { echo "PASS  - $1"; PASS=$((PASS+1)); record "$1" "PASS" "info" "${2:-}"; }
fail()  { echo "FAIL  - $1"; FAIL=$((FAIL+1)); record "$1" "FAIL" "blocker" "${2:-}"; }
warn()  { echo "WARN  - $1"; WARN=$((WARN+1)); record "$1" "WARN" "advice" "${2:-}"; }

# ---- RUN TESTS ----
start_report

# 1) PDF exists and is a real PDF
if [ -f docs/Ozirus_Dilemma.pdf ] && [ -s docs/Ozirus_Dilemma.pdf ]; then
  mime=$(file -b --mime-type docs/Ozirus_Dilemma.pdf || echo unknown)
  if [[ "$mime" == "application/pdf"* ]]; then
    pass "docs/Ozirus_Dilemma.pdf exists and is a PDF"
  else
    warn "PDF MIME check" "Found file, but MIME type is '$mime'. If it opens fine, ignore; else re-export as PDF."
  fi
  size=$(stat -c %s docs/Ozirus_Dilemma.pdf 2>/dev/null || stat -f %z docs/Ozirus_Dilemma.pdf)
  if [ "${size:-0}" -lt 10240 ]; then
    warn "PDF size seems small" "Size=${size} bytes. Make sure it's the final compiled PDF, not a placeholder."
  fi
else
  fail "docs/Ozirus_Dilemma.pdf missing" "Put your final PDF at docs/Ozirus_Dilemma.pdf."
fi

# 2) README links to the PDF
if [ -f README.md ]; then
  if grep -q "docs/Ozirus_Dilemma.pdf" README.md; then
    pass "README links to docs/Ozirus_Dilemma.pdf"
  else
    fail "README link missing" "Add a link to docs/Ozirus_Dilemma.pdf inside README.md."
  fi
else
  fail "README.md missing" "Create README.md that explains the project and links to the PDF."
fi

# 3) LICENSE-CODE (Apache 2.0)
if [ -f LICENSE-CODE ] && [ -s LICENSE-CODE ]; then
  if grep -qi "Apache License" LICENSE-CODE; then
    pass "LICENSE-CODE looks like Apache 2.0"
  else
    warn "LICENSE-CODE content check" "File exists but didn't detect 'Apache License' string. Ensure this is the official text."
  fi
else
  fail "LICENSE-CODE missing" "Download the official text from https://www.apache.org/licenses/LICENSE-2.0.txt and save as LICENSE-CODE."
fi

# 4) LICENSE-DOCS (CC BY 4.0)
if [ -f LICENSE-DOCS ] && [ -s LICENSE-DOCS ]; then
  if grep -qi "Creative Commons" LICENSE-DOCS && grep -qi "Attribution" LICENSE-DOCS && grep -qi "4.0" LICENSE-DOCS; then
    pass "LICENSE-DOCS looks like CC BY 4.0"
  else
    warn "LICENSE-DOCS content check" "File exists but CC BY 4.0 strings weren't all detected. Make sure it's the official text."
  fi
else
  fail "LICENSE-DOCS missing" "Download the official text from https://creativecommons.org/licenses/by/4.0/legalcode.txt and save as LICENSE-DOCS."
fi

# 5) NOTICE explains license split
if [ -f NOTICE ] && [ -s NOTICE ]; then
  if grep -qi "two kinds of content" NOTICE && grep -qi "Apache" NOTICE && grep -qi "Creative Commons" NOTICE; then
    pass "NOTICE explains the code/docs license split"
  else
    warn "NOTICE wording" "NOTICE exists; make sure it explains Apache for code and CC BY 4.0 for docs."
  fi
else
  fail "NOTICE missing" "Add a NOTICE file that explains the two-license split (code vs docs)."
fi

# 6) CITATION.cff basic fields
if [ -f CITATION.cff ] && [ -s CITATION.cff ]; then
  base_ok=true
  for key in "cff-version:" "title:" "authors:" "repository-code:"; do
    if ! grep -q "$key" CITATION.cff; then base_ok=false; fi
  done
  if $base_ok; then
    if grep -q "<your-username>" CITATION.cff; then
      warn "CITATION repository-code placeholder" "Replace <your-username> with your GitHub username in repository-code."
    else
      pass "CITATION.cff has key fields and repository-code"
    fi
  else
    fail "CITATION.cff missing fields" "Ensure it has cff-version, title, authors, and repository-code."
  fi
else
  fail "CITATION.cff missing" "Create CITATION.cff so others can cite your work."
fi

# 7) Git remote (optional)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git config --get remote.origin.url >/dev/null; then
    pass "Git remote is set" "$(git config --get remote.origin.url)"
  else
    warn "No git remote" "Set one with: git remote add origin git@github.com:<your-username>/ozirus-dilemma.git"
  fi
else
  warn "Not a git repo" "Run 'git init' if you want to version-control and push to GitHub."
fi

# 8) src/Ozirus_Dilemma.tex (optional)
if [ -f src/Ozirus_Dilemma.tex ]; then
  pass "Found src/Ozirus_Dilemma.tex (optional)"
else
  warn "No LaTeX source found (optional)" "You said you already have the PDF. Keeping the .tex is optional."
fi

finish_report

# Final exit code
if [ "$FAIL" -gt 0 ]; then
  echo "
Result: FAIL ($FAIL blocker issue(s)). See repo_smoke_report.json for details." >&2
  exit 1
else
  echo "
Result: OK (no blockers). Warnings: $WARN. See repo_smoke_report.json for details."
  exit 0
fi
