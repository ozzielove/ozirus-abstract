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
  note_escaped=$(printf '%s' "$note" | sed 's/\\/\\\\/g; s/"/\\"/g')
  printf '  {"name":"%s","status":"%s","severity":"%s","note":"%s"}' "$name" "$status" "$severity" "$note_escaped" >> "$TMP"
}

pass()  { echo "PASS  - $1"; PASS=$((PASS+1)); record "$1" "PASS" "info" "${2:-}"; }
fail()  { echo "FAIL  - $1"; FAIL=$((FAIL+1)); record "$1" "FAIL" "blocker" "${2:-}"; }
warn()  { echo "WARN  - $1"; WARN=$((WARN+1)); record "$1" "WARN" "advice" "${2:-}"; }

get_size() {
  if stat -c %s "$1" >/dev/null 2>&1; then stat -c %s "$1"; else stat -f %z "$1"; fi
}

start_report

# 1) PDF check
if [ -f docs/Ozirus_Dilemma.pdf ] && [ -s docs/Ozirus_Dilemma.pdf ]; then
  mime=$(file -b --mime-type docs/Ozirus_Dilemma.pdf || echo unknown)
  if [[ "$mime" == application/pdf* ]]; then
    pass "PDF exists and looks like a PDF"
  else
    warn "PDF MIME check" "We found the file but its type is '$mime'. If it opens fine, ignore this warning."
  fi
  size=$(get_size docs/Ozirus_Dilemma.pdf)
  if [ "${size:-0}" -lt 10240 ]; then
    warn "PDF may be too small" "Size=${size} bytes. Make sure this is your final compiled PDF."
  fi
else
  fail "Missing PDF" "Put your final PDF at docs/Ozirus_Dilemma.pdf"
fi

# 2) README link to PDF
if [ -f README.md ]; then
  if grep -qi "docs/Ozirus_Dilemma.pdf" README.md; then
    pass "README links to the PDF"
  else
    fail "README missing PDF link" "Add a line like: [View the Ozirus Dilemma PDF](docs/Ozirus_Dilemma.pdf)"
  fi
else
  fail "README.md missing" "Create a README.md that explains the project and links to the PDF"
fi

# 3) LICENSE-CODE (Apache)
if [ -f LICENSE-CODE ] && [ -s LICENSE-CODE ]; then
  if grep -qi "Apache License" LICENSE-CODE; then
    pass "LICENSE-CODE is Apache 2.0"
  else
    warn "LICENSE-CODE content" "File exists but string 'Apache License' not detected. Make sure it's the official text."
  fi
else
  fail "LICENSE-CODE missing" "Save the official Apache 2.0 text as LICENSE-CODE"
fi

# 4) LICENSE-DOCS (CC BY 4.0)
if [ -f LICENSE-DOCS ] && [ -s LICENSE-DOCS ]; then
  if grep -qi "Creative Commons" LICENSE-DOCS && grep -qi "Attribution" LICENSE-DOCS && grep -qi "4.0" LICENSE-DOCS; then
    pass "LICENSE-DOCS is CC BY 4.0"
  else
    warn "LICENSE-DOCS content" "File exists but CC BY 4.0 strings not all detected. Make sure it's the official text."
  fi
else
  fail "LICENSE-DOCS missing" "Save the official CC BY 4.0 legal code as LICENSE-DOCS"
fi

# 5) NOTICE (license split)
if [ -f NOTICE ] && [ -s NOTICE ]; then
  if grep -qi "two kinds of content" NOTICE && grep -qi "Apache" NOTICE && grep -qi "Creative Commons" NOTICE; then
    pass "NOTICE explains the two-license split"
  else
    warn "NOTICE wording" "NOTICE exists; ensure it says Apache for code and CC BY for docs"
  fi
else
  fail "NOTICE missing" "Add a NOTICE that explains the two-license split"
fi

# 6) CITATION.cff
if [ -f CITATION.cff ] && [ -s CITATION.cff ]; then
  ok=true
  for k in "cff-version:" "title:" "authors:" "repository-code:"; do
    if ! grep -q "$k" CITATION.cff; then ok=false; fi
  done
  if $ok; then
    if grep -q "<your-username>" CITATION.cff; then
      warn "CITATION repository-code placeholder" "Replace <your-username> with your real GitHub username"
    else
      pass "CITATION.cff has key fields and a real repo URL"
    fi
  else
    fail "CITATION.cff missing fields" "Add cff-version, title, authors, repository-code"
  fi
else
  fail "CITATION.cff missing" "Create CITATION.cff so people can cite your work"
fi

# 7) Git remote (optional)
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git config --get remote.origin.url >/dev/null; then
    pass "Git remote set" "$(git config --get remote.origin.url)"
  else
    warn "No git remote" "Set one with: git remote add origin git@github.com:<your-username>/ozirus-dilemma.git"
  fi
else
  warn "Not a git repo" "Run 'git init' if you want to push to GitHub"
fi

# 8) LaTeX source (optional)
if [ -f src/Ozirus_Dilemma.tex ]; then
  pass "Found src/Ozirus_Dilemma.tex (optional)"
else
  warn "No LaTeX source" "You already ship the PDF. Keeping .tex is optional"
fi

# Write JSON report
{
  echo '{'
  echo "  \"summary\": \"Smoke test complete.\","
  echo "  \"pass\": $PASS,"
  echo "  \"fail\": $FAIL,"
  echo "  \"warn\": $WARN,"
  echo "  \"remote\": \"$REMOTE\","
  echo "  \"messages\": ["
  for i in "${!msgs[@]}"; do
    sep=","
    [ "$i" = "$((${#msgs[@]}-1))" ] && sep=""
    printf '    "%s"%s\n' "${msgs[$i]//\"/\\\"}" "$sep"
  done
  echo "  ],"
  if [ "$FAIL" -eq 0 ]; then
    echo "  \"ok\": true"
  else
    echo "  \"ok\": false"
  fi
  echo '}'
} > "$REPO_JSON"

echo
if [ "$FAIL" -eq 0 ]; then
  echo "Result: OK (no blockers). Warnings: $WARN. See $REPO_JSON for details."
  exit 0
else
  echo "Result: FAILED ($FAIL blockers). Warnings: $WARN. See $REPO_JSON for details."
  exit 1
fifi
