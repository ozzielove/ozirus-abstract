#!/usr/bin/env bash
# Safe, read-only checks. Writes final_smoke_report.json and exits 0 on success.

set -eo pipefail

PASS=0
FAIL=0
WARN=0
msgs=()

repo_url="$(git ls-remote --get-url origin 2>/dev/null || echo "")"
pdf_path="docs/Ozirus_Dilemma.pdf"

pass(){ echo "PASS - $1"; msgs+=("PASS - $1"); PASS=$((PASS+1)); }
fail(){ echo "FAIL - $1"; msgs+=("FAIL - $1"); FAIL=$((FAIL+1)); }
warn(){ echo "WARN - $1"; msgs+=("WARN - $1"); WARN=$((WARN+1)); }

check_file(){
  local f="$1" label="$2"
  if [[ -f "$f" ]]; then pass "$label present ($f)"; else fail "$label missing ($f)"; fi
}

check_readme_links(){
  if [[ -f README.md ]]; then
    grep -q "docs/Ozirus_Dilemma.pdf" README.md && pdfok=1 || pdfok=0
    grep -q "ozzielove.github.io/ozirus-dilemma" README.md && pageok=1 || pageok=0
    ((pdfok==1)) && pass "README links to PDF" || fail "README missing PDF link"
    ((pageok==1)) && pass "README links to landing page" || warn "README missing landing page link"
  else
    fail "README.md missing"
  fi
}

check_doi_badge(){
  if [[ -f README.md ]]; then
    if grep -q "zenodo" README.md; then pass "README has DOI badge (may be PENDING)"; else warn "DOI badge not found in README"; fi
  fi
}

check_pages_live(){
  # Requires network. Accept 200 or any 30x.
  local url="https://ozzielove.github.io/ozirus-dilemma/"
  if command -v curl >/dev/null 2>&1; then
    code="$(curl -sI "$url" | awk 'NR==1{print $2}')"
    if [[ "$code" =~ ^2|3 ]]; then pass "Pages site responds ($code)"; else warn "Pages check non-OK HTTP ($code)"; fi
  else
    warn "curl not found; skipping Pages check"
  fi
}

check_release_tag(){
  # Check remote tag exists (v1.0.0 or v1.0.1)
  if git ls-remote --tags origin | grep -Eq 'refs/tags/v1\.0\.(0|1)$'; then
    pass "Release tag v1.0.0/1.0.1 exists on remote"
  else
    warn "No v1.0.0 or v1.0.1 release tag found on remote"
  fi
}

check_citation(){
  if [[ -f CITATION.cff ]]; then
    grep -q "$repo_url" CITATION.cff && pass "CITATION.cff has real repo URL" || warn "CITATION.cff missing real repo URL"
    grep -qi '^doi:' CITATION.cff && pass "CITATION.cff has a DOI" || warn "CITATION.cff DOI not set yet"
  else
    warn "CITATION.cff missing"
  fi
}

check_json_guide(){
  if [[ -f ozirus_troubleshoot_guide.json ]]; then
    if command -v jq >/dev/null 2>&1; then
      if jq empty ozirus_troubleshoot_guide.json 2>/dev/null; then pass "JSON troubleshooting guide is valid JSON"; else warn "JSON troubleshooting guide not valid JSON"; fi
    else
      pass "JSON troubleshooting guide present (jq not installed; basic check only)"
    fi
  else
    warn "JSON troubleshooting guide missing"
  fi
}

check_demo_and_page(){
  [[ -f docs/index.md ]] && pass "Landing page present (docs/index.md)" || warn "Landing page missing (docs/index.md)"
  [[ -f demo/sda_pcp_rgm_demo.py ]] && pass "Demo script present" || warn "Demo script missing"
}

# --- Run checks ---
[[ -n "$repo_url" ]] && pass "Git remote set ($repo_url)" || warn "Git remote not set"
check_file "$pdf_path" "PDF"
check_readme_links
check_doi_badge
check_pages_live
check_release_tag
check_citation
check_json_guide
check_demo_and_page
check_file "LICENSE-CODE" "LICENSE-CODE"
check_file "LICENSE-DOCS" "LICENSE-DOCS"
check_file "NOTICE" "NOTICE"

# --- Report ---
{
  echo '{'
  echo '  "summary": "Final smoke test complete.",'
  echo "  \"pass\": $PASS,"
  echo "  \"fail\": $FAIL,"
  echo "  \"warn\": $WARN,"
  echo "  \"remote\": \"${repo_url//\"/\\\"}\","
  echo '  "messages": ['
  for i in "${!msgs[@]}"; do
    sep=","
    [[ "$i" == "$((${#msgs[@]}-1))" ]] && sep=""
    printf '    "%s"%s\n' "${msgs[$i]//\"/\\\"}" "$sep"
  done
  echo '  ],'
  if [[ "$FAIL" -eq 0 ]]; then
    echo '  "ok": true'
  else
    echo '  "ok": false'
  fi
  echo '}'
} > final_smoke_report.json

echo
if [[ "$FAIL" -eq 0 ]]; then
  echo "Result: OK (no blockers). Warnings: $WARN. See final_smoke_report.json"
  exit 0
else
  echo "Result: FAILED ($FAIL blockers). Warnings: $WARN. See final_smoke_report.json"
  exit 1
fi
