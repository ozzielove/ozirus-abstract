#!/usr/bin/env bash
set -euo pipefail

# Optional environment variables you can set before running:
#   export GH_REPO_URL="https://github.com/ozzielove/ozirus-dilemma"
#   export DOI="10.5281/zenodo.XXXXXXX"

BACKUP_SUFFIX=".bak_ozd"

say() { echo "$1"; }
ensure_dir() { mkdir -p "$1"; }
ensure_file() { [ -f "$1" ] || printf '' > "$1"; }

insert_line_top_if_missing() {
  # $1=file  $2=exact_line
  local f="$1"; local line="$2"
  ensure_file "$f"
  if ! grep -Fqs "$line" "$f"; then
    tmp="${f}.tmp.$$"
    { printf '%s\n' "$line"; cat "$f"; } > "$tmp"
    mv "$f""$BACKUP_SUFFIX" || true
    mv "$tmp" "$f"
    say "Added line to top of $f"
  else
    say "Already present in $f: $line"
  fi
}

append_if_missing() {
  # $1=file  $2=exact_line
  local f="$1"; local line="$2"
  ensure_file "$f"
  if ! grep -Fqs "$line" "$f"; then
    printf '\n%s\n' "$line" >> "$f"
    say "Appended to $f"
  else
    say "Already present in $f: $line"
  fi
}

safe_sed_replace() {
  # $1=file  $2=regex  $3=replacement (sed style)
  local f="$1" rx="$2" rep="$3"
  ensure_file "$f"
  cp "$f" "${f}${BACKUP_SUFFIX}" || true
  # Try BSD sed then GNU sed
  if sed -E -i '' "$rx" "$f" 2>/dev/null; then
    :
  else
    sed -E -i "$rx" "$f"
  fi
}

ensure_dir docs
ensure_dir src

# 1) Ensure README has the download line and tagline
if [ -f README.md ]; then :; else printf '# Ozirus's Dilemma\n\n' > README.md; fi

DL_LINE='📄 **Download:** [Ozirus_Dilemma.pdf](docs/Ozirus_Dilemma.pdf) • 🌐 [Landing page](https://ozzielove.github.io/ozirus-dilemma/)'
insert_line_top_if_missing README.md "$DL_LINE"

TAGLINE='Predict short-horizon risk, allocate minutes, and prove it (CRT → Merkle → signature).'
if ! grep -Fqs "$TAGLINE" README.md; then
  safe_sed_replace README.md '1 a\\\n'"$TAGLINE"''
  say "Inserted tagline under the first line in README.md"
else
  say "Tagline already present in README.md"
fi

# 2) NOTICE (dual license explainer)
if [ ! -f NOTICE ]; then
  cat > NOTICE <<'EOF'
This repository has two kinds of content with different licenses:

1) CODE (algorithms, pseudocode, scripts, CI, Makefiles):
   Licensed under the Apache License, Version 2.0 (see LICENSE-CODE).

2) DOCS (the manuscript text, figures, diagrams, and PDF outputs):
   Licensed under the Creative Commons Attribution 4.0 International License (see LICENSE-DOCS).

By contributing, you agree your contributions are licensed under the matching license above.
EOF
  say "Wrote NOTICE"
else
  say "NOTICE already exists"
fi

# 3) CITATION.cff minimal checks/patches
if [ ! -f CITATION.cff ]; then
  cat > CITATION.cff <<'EOF'
cff-version: 1.2.0
title: "Ozirus's Dilemma: Predict, Decide, Prove"
message: "If you use this work, please cite it."
type: report
authors:
  - family-names: Morency
    given-names: Ozirus
license: Apache-2.0
repository-code: "https://github.com/ozzielove/ozirus-dilemma"
EOF
  say "Created basic CITATION.cff"
fi

# Replace placeholder repository-code if env var provided
if [ "${GH_REPO_URL-}" != "" ]; then
  safe_sed_replace CITATION.cff 's#(repository-code: ")https?://github\.com/[^"]+("#\1'"$GH_REPO_URL"'\2#'
  if grep -Fqs "$GH_REPO_URL" CITATION.cff; then say "CITATION updated with GH_REPO_URL"; fi
fi

# Add/replace DOI if provided
if [ "${DOI-}" != "" ]; then
  if grep -Eq '^doi:' CITATION.cff; then
    safe_sed_replace CITATION.cff 's#^doi:.*#doi: '"$DOI"'#'
  else
    printf 'doi: %s\n' "$DOI" >> CITATION.cff
  fi
  say "CITATION.cff DOI set to $DOI"
fi

# 4) Create a simple landing page if missing
if [ ! -f docs/index.md ]; then
  cat > docs/index.md <<'EOF'
# Ozirus's Dilemma

**Download the paper:** [Ozirus_Dilemma.pdf](./Ozirus_Dilemma.pdf)

This page is for quick access to the PDF. For more details, visit the GitHub repository.

- Repo: [https://github.com/ozzielove/ozirus-dilemma
EOF
  say "Wrote docs/index.md (landing page)"
else
  say "docs/index.md already exists"
fi

# 5) Licenses (do not overwrite if present)

[ -f LICENSE-CODE ] || { curl -fsSL https://www.apache.org/licenses/LICENSE-2.0.txt -o LICENSE-CODE && say "Wrote LICENSE-CODE"; }

[ -f LICENSE-DOCS ] || { curl -fsSL https://creativecommons.org/licenses/by/4.0/legalcode.txt -o LICENSE-DOCS || curl -fsSL https://creativecommons.org/licenses/by/4.0/legalcode -o LICENSE-DOCS; say "Wrote LICENSE-DOCS"; }

# 6) Friendly reminder if PDF missing
if [ ! -f docs/Ozirus_Dilemma.pdf ]; then
  say "NOTE: Put your final PDF at docs/Ozirus_Dilemma.pdf"
fi

say "Done. Now run: bash smoke_test.sh"
