#!/usr/bin/env bash
set -euo pipefail

PASS=0
FAIL=0
WARN=0
TMP="repo_integration_report.json.tmp"
FIRST=1

start_report() { echo '{"tests": [' > "$TMP"; }
finish_report() {
  echo '], "summary": {"pass": '"$PASS"', "fail": '"$FAIL"', "warn": '"$WARN"'}, "ok": '"$([ "$FAIL" -eq 0 ] && echo true || echo false)"', "timestamp": '"\"'"$(date -u +%FT%TZ)"'\"' }' >> "$TMP"
  mv "$TMP" repo_integration_report.json
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

backup_readme() {
  local ts=$(date +%Y%m%d%H%M%S)
  cp README.md "README.md.bak.$ts"
  echo "Made backup: README.md.bak.$ts"
}

ensure_readme_with_link() {
  if [ ! -f README.md ]; then
    echo "README.md not found. Creating a new one with the PDF link."
    cat > README.md <<'MD'
# Ozirus's Dilemma: Predict, Decide, Prove

This repo contains the paper and examples for **Ozirus's Dilemma** — a pipeline that:
- **Predicts** short-term risk (SDA),
- **Decides** how to spend minutes across actions (PCP),
- **Proves** what you did with a signed receipt (RGM: CRT → Merkle → signature).

## Read the Paper

- **PDF:** [View the Ozirus Dilemma PDF](docs/Ozirus_Dilemma.pdf)
- **LaTeX source:** `src/Ozirus_Dilemma.tex` (optional)

## License

- **Code & pseudocode:** Apache-2.0 — see `LICENSE-CODE`
- **Paper text & figures:** CC BY 4.0 — see `LICENSE-DOCS`

See `NOTICE` to understand the split.
MD
    pass "Created README with PDF link"
    return
  fi

  if grep -qi "docs/Ozirus_Dilemma.pdf" README.md; then
    pass "README already has PDF link"
  else
    backup_readme
    cat >> README.md <<'MD'

## Read the Paper

- **PDF:** [View the Ozirus Dilemma PDF](docs/Ozirus_Dilemma.pdf)
MD
    pass "Added PDF link section to README"
  fi
}

# ---- RUN ----
start_report

# Fix the README link if needed
ensure_readme_with_link

# Now run the same checks as the smoke test (inline, trimmed)

# 1) PDF exists
if [ -f docs/Ozirus_Dilemma.pdf ] && [ -s docs/Ozirus_Dilemma.pdf ]; then
  pass "PDF exists after fix"
else
  fail "Missing PDF after fix" "Place your PDF at docs/Ozirus_Dilemma.pdf"
fi

# 2) README link present
if grep -qi "docs/Ozirus_Dilemma.pdf" README.md; then
  pass "README links to PDF after fix"
else
  fail "README still missing PDF link" "Manual edit needed; add the link"
fi

# 3) LICENSE-CODE
if [ -f LICENSE-CODE ] && [ -s LICENSE-CODE ]; then
  pass "LICENSE-CODE present"
else
  fail "LICENSE-CODE missing" "Add official Apache 2.0 text as LICENSE-CODE"
fi

# 4) LICENSE-DOCS
if [ -f LICENSE-DOCS ] && [ -s LICENSE-DOCS ]; then
  pass "LICENSE-DOCS present"
else
  fail "LICENSE-DOCS missing" "Add official CC BY 4.0 text as LICENSE-DOCS"
fi

# 5) NOTICE
if [ -f NOTICE ] && [ -s NOTICE ]; then
  pass "NOTICE present"
else
  fail "NOTICE missing" "Add a NOTICE explaining the two-license split"
fi

# 6) CITATION.cff (basic presence)
if [ -f CITATION.cff ] && [ -s CITATION.cff ]; then
  if grep -q "<your-username>" CITATION.cff; then
    warn "CITATION repository-code placeholder" "Replace <your-username> with your real GitHub username"
  else
    pass "CITATION.cff present and likely OK"
  fi
else
  fail "CITATION.cff missing" "Create CITATION.cff"
fi

finish_report

if [ "$FAIL" -gt 0 ]; then
  echo
  echo "Result: FAIL ($FAIL blocker issue(s)). See repo_integration_report.json for details." >&2
  exit 1
else
  echo
  echo "Result: OK (no blockers). Warnings: $WARN. See repo_integration_report.json for details."
  exit 0
fi
