#!/usr/bin/env bash
set -euo pipefail

# Safe, resume-able finisher. It only adds what is missing.
# Usage:
#   ./resume_all.sh                # just check/fix
#   ./resume_all.sh --doi 10.5281/zenodo.XXXX   # also set real DOI
#   ./resume_all.sh --make-release  # try to create v1.0.0 release via gh

DOI=""
MAKE_RELEASE=0
REPO_URL="https://github.com/ozzielove/ozirus-dilemma"
PDF_PATH="docs/Ozirus_Dilemma.pdf"
REPORT="resume_report.json"
NOWTS=$(date +%Y%m%dT%H%M%S)
PASS=0
FAIL=0
WARN=0
msgs=()

# Parse args
while [[ ${1-} =~ ^- ]]; do
  case "$1" in
    --doi)
      shift
      DOI=${1-}
      ;;
    --make-release)
      MAKE_RELEASE=1
      ;;
    *)
      echo "Unknown option: $1" >&2; exit 2
      ;;
  esac
  shift || true
done

say() { echo "$@"; }
pass() { PASS=$((PASS+1)); msgs+=("PASS - $1"); }
fail() { FAIL=$((FAIL+1)); msgs+=("FAIL - $1"); }
warn() { WARN=$((WARN+1)); msgs+=("WARN - $1"); }

need_git_repo() {
  if [[ ! -d .git ]]; then
    fail ".git folder not found. Run this in your local repo folder."
    finish 1
  fi
}

ensure_pdf() {
  if [[ -f "$PDF_PATH" ]]; then
    if head -c 4 "$PDF_PATH" | grep -q '%PDF'; then
      pass "PDF exists and looks like a PDF ($PDF_PATH)"
    else
      warn "PDF exists but does not look like a PDF header ($PDF_PATH)"
    fi
  else
    fail "Missing $PDF_PATH. Put your final PDF there."
  fi
}

ensure_readme_links() {
  if [[ ! -f README.md ]]; then
    echo "# Ozirus's Dilemma: Predict, Decide, Prove" > README.md
    echo >> README.md
    say "Created README.md"
  fi

  if grep -q "docs/Ozirus_Dilemma.pdf" README.md && grep -q "ozzielove.github.io/ozirus-dilemma" README.md; then
    pass "README already has PDF + landing page links"
  else
    cp README.md README.md.bak.$NOWTS
    { printf "Download: [Ozirus_Dilemma.pdf](docs/Ozirus_Dilemma.pdf) | Landing page: https://ozzielove.github.io/ozirus-dilemma/\n\n"; cat README.md; } > README.tmp && mv README.tmp README.md
    pass "Added top PDF + landing links to README"
  fi

  if grep -q "Predict short-horizon risk, allocate minutes, and prove it" README.md; then
    pass "README tagline present"
  else
    tmpfile=$(mktemp)
    printf "Predict short-horizon risk, allocate minutes, and prove it (CRT to Merkle to signature).\n\n" > "$tmpfile"
    cat README.md >> "$tmpfile"
    mv "$tmpfile" README.md
    pass "Added tagline to README"
  fi

  local BADGE_LINE="[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.PENDING.svg)](https://doi.org/10.5281/zenodo.PENDING)"
  if [[ -n "$DOI" ]]; then
    BADGE_LINE="[![DOI](https://zenodo.org/badge/DOI/$DOI.svg)](https://doi.org/$DOI)"
  fi
  if grep -q "zenodo" README.md; then
    if [[ -n "$DOI" ]]; then
      sed -i.bak_$NOWTS "s@10.5281/zenodo.PENDING@$DOI@g" README.md || true
      pass "Updated README DOI to $DOI"
    else
      pass "README has a DOI badge (may be PENDING)"
    fi
  else
    cp README.md README.md.bak2.$NOWTS
    { printf "%s\n\n" "$BADGE_LINE"; cat README.md; } > README.tmp && mv README.tmp README.md
    pass "Added DOI badge to README"
  fi
}

ensure_docs_index() {
  mkdir -p docs
  if [[ -f docs/index.md ]]; then
    pass "docs/index.md already exists"
  else
    local DOI_SHOW="10.5281/zenodo.PENDING"
    [[ -n "$DOI" ]] && DOI_SHOW="$DOI"
    cat > docs/index.md <<DOCEOF
# Ozirus's Dilemma: Predict, Decide, Prove

**One line:** Predict short-horizon risk, allocate minutes, and prove it (CRT to Merkle to signature).

[Download the PDF](./Ozirus_Dilemma.pdf)

**Repo:** $REPO_URL  
**Release:** $REPO_URL/releases  
**DOI:** $DOI_SHOW (replace when real)

## What this is (super short)
1) **Predict** near-term risk.
2) **Decide** how to use your limited minutes.
3) **Prove** what you did with CRT to Merkle to signature.

## How to cite
Morency, O. (2025). *Ozirus's Dilemma: Predict, Decide, Prove.* v1.0.0. DOI: $DOI_SHOW
DOCEOF
    pass "Created docs/index.md"
  fi
  if [[ ! -f docs/.nojekyll ]]; then
    touch docs/.nojekyll
  fi
}

ensure_demo() {
  if [[ -f demo/sda_pcp_rgm_demo.py ]]; then
    pass "Demo script already exists"
    return
  fi
  mkdir -p demo
  cat > demo/sda_pcp_rgm_demo.py <<PYEOF
#!/usr/bin/env python3
# Tiny toy demo. NOT real crypto; shows the pipeline idea.
import math, hashlib, json

def hazard(lam, tau):
    return 1 - math.exp(-lam * tau)

def clip(x, lo, hi):
    return max(lo, min(hi, x))

def water_filling(a, umax, B, eps=1e-6):
    lo = min(-ai - umax[i] for i, ai in enumerate(a))
    hi = max(-ai for ai in a)
    while hi - lo > eps:
        lam = 0.5 * (lo + hi)
        u = [clip(-ai - lam, 0.0, umax[i]) for i, ai in enumerate(a)]
        if sum(u) > B:
            lo = lam
        else:
            hi = lam
    lam = 0.5 * (lo + hi)
    return [clip(-ai - lam, 0.0, umax[i]) for i, ai in enumerate(a)]

def quantize(x, Delta):
    return [int(round(v/Delta)) for v in x]

def inner(a, x):
    return sum(ai*xi for ai, xi in zip(a, x))

def residues(Arows, xq, primes):
    return [inner(a, xq) % p for a, p in zip(Arows, primes)]

def merkle_root(leaves_bytes):
    layer = [hashlib.sha256(b).digest() for b in leaves_bytes]
    if not layer:
        return b""
    while len(layer) > 1:
        if len(layer) % 2 == 1:
            layer.append(layer[-1])
        nxt = []
        for i in range(0, len(layer), 2):
            nxt.append(hashlib.sha256(layer[i] + layer[i+1]).digest())
        layer = nxt
    return layer[0]

def main():
    mu, omega, delta = 0.012, 0.18, 0.12
    bumps = 0.04
    past_mins = [25, 12, 4]
    tau = 8.0
    L = [3, 5, 7]
    umax = [8, 10, 12]
    B = 24.0
    Delta = 0.01
    Arows = [[2,1,0,3],[1,4,1,2],[3,0,5,1]]
    primes = [101,103,107]
    excit = sum(math.exp(-delta*t) for t in past_mins)
    lam = mu + omega*excit + bumps
    h = hazard(lam, tau)
    a = [-h*Li for Li in L]
    u = water_filling(a, umax, B)
    x = [h] + u
    xq = quantize(x, Delta)
    r = residues(Arows, xq, primes)
    metas = [b"meta1", b"meta2", b"meta3"]
    leaves = [hashlib.sha256(str(ri).encode() + b"||" + mi).digest() for ri, mi in zip(r, metas)]
    root = merkle_root(leaves)
    print(json.dumps({
        "xq": xq,
        "residues": r,
        "primes": primes,
        "merkle_root_hex": root.hex(),
        "policy": "demo-only"
    }, indent=2))
if __name__ == "__main__":
    main()
PYEOF
  chmod +x demo/sda_pcp_rgm_demo.py
  pass "Created demo/sda_pcp_rgm_demo.py"
}

ensure_notice_and_licenses() {
  [[ -f LICENSE-CODE ]] && pass "LICENSE-CODE present" || warn "LICENSE-CODE missing"
  [[ -f LICENSE-DOCS ]] && pass "LICENSE-DOCS present" || warn "LICENSE-DOCS missing"
  [[ -f NOTICE ]] && pass "NOTICE present" || warn "NOTICE missing"
}

update_citation() {
  if [[ ! -f CITATION.cff ]]; then
    warn "CITATION.cff missing (skipping update)"
    return
  fi
  if grep -q "repository-code:" CITATION.cff; then
    sed -i.bak_$NOWTS "s@repository-code:.*@repository-code: \"$REPO_URL\"@" CITATION.cff || true
  else
    echo "repository-code: \"$REPO_URL\"" >> CITATION.cff
  fi
  if [[ -n "$DOI" ]]; then
    if grep -q "^doi:" CITATION.cff; then
      sed -i.bak_$NOWTS "s@^doi:.*@doi: $DOI@" CITATION.cff || true
    else
      echo "doi: $DOI" >> CITATION.cff
    fi
    pass "CITATION.cff updated with DOI and repo URL"
  else
    pass "CITATION.cff has repo URL; DOI update skipped (no --doi given)"
  fi
}

maybe_make_release() {
  if [[ $MAKE_RELEASE -ne 1 ]]; then
    warn "Release step skipped (run with --make-release to try)"
    return
  fi
  if ! command -v gh >/dev/null 2>&1; then
    warn "GitHub CLI (gh) not found; cannot create release automatically"
    return
  fi
  if gh release view v1.0.0 >/dev/null 2>&1; then
    pass "Release v1.0.0 already exists"
  else
    if [[ -f "$PDF_PATH" ]]; then
      gh release create v1.0.0 "$PDF_PATH" -t "Ozirus's Dilemma v1.0.0" -n "First public release." && pass "Created release v1.0.0 with PDF"
    else
      warn "Cannot create release: $PDF_PATH missing"
    fi
  fi
}

commit_and_push() {
  if [[ -n "$(git status --porcelain)" ]]; then
    git add -A
    git commit -m "repo: auto-resume polish (README links/badge, docs/index.md, demo, citation)"
    git pull --rebase --autostash origin main || true
    if git rev-parse --abbrev-ref HEAD | grep -q '^main$'; then
      git push origin main || warn "Push failed. Resolve any git conflicts, then re-run."
    else
      warn "Not on 'main' branch; skipping push."
    fi
    pass "Committed local changes"
  else
    pass "No local changes to commit"
  fi
}

final_checks() {
  if grep -q "docs/Ozirus_Dilemma.pdf" README.md && grep -q "ozzielove.github.io/ozirus-dilemma" README.md; then
    pass "README: links OK"
  else
    fail "README: missing links"
  fi
  [[ -f "$PDF_PATH" ]] && pass "PDF: present" || fail "PDF: missing"
  [[ -f docs/index.md ]] && pass "Landing page: present" || fail "Landing page: missing"
  [[ -f demo/sda_pcp_rgm_demo.py ]] && pass "Demo: present" || fail "Demo: missing"
  if [[ -f CITATION.cff ]] && grep -q "$REPO_URL" CITATION.cff; then
    pass "CITATION: repo URL present"
  else
    warn "CITATION: repo URL missing or CITATION.cff absent"
  fi
}

finish() {
  {
    echo '{'
    echo "  \"summary\": \"Resume script complete.\"," 
    echo "  \"pass\": $PASS,"
    echo "  \"fail\": $FAIL,"
    echo "  \"warn\": $WARN,"
    echo "  \"messages\": ["
    for i in "${!msgs[@]}"; do
      sep=","; [[ "$i" == "$((${#msgs[@]}-1))" ]] && sep=""
      printf '    "%s"%s\n' "${msgs[$i]//\"/\\\"}" "$sep"
    done
    echo "  ],"
    if [[ "$FAIL" -eq 0 ]]; then
      echo "  \"ok\": true"
    else
      echo "  \"ok\": false"
    fi
    echo '}'
  } > "$REPORT"

  echo
  if [[ "$FAIL" -eq 0 ]]; then
    echo "Result: OK (no blockers). Warnings: $WARN. See $REPORT for details."
    exit 0
  else
    echo "Result: FAILED ($FAIL blockers). Warnings: $WARN. See $REPORT for details."
    exit 1
  fi
}

# --- Run ---
need_git_repo
ensure_pdf
ensure_readme_links
ensure_docs_index
ensure_demo
ensure_notice_and_licenses
update_citation
maybe_make_release
commit_and_push
final_checks
finish
