#!/usr/bin/env bash
set -euo pipefail

echo "Integration Fix: Adding PDF link to README.md"

# Check if README.md exists and has the PDF link
if [ -f README.md ]; then
  if grep -qi "docs/Ozirus_Dilemma.pdf" README.md; then
    echo "PASS - README already has PDF link"
  else
    # Make backup
    ts=$(date +%Y%m%d%H%M%S)
    cp README.md "README.md.bak.$ts"
    echo "Made backup: README.md.bak.$ts"
    
    # Add PDF link section
    cat >> README.md <<'EOF'

## Read the Paper

- **PDF:** [View the Ozirus Dilemma PDF](docs/Ozirus_Dilemma.pdf)
EOF
    echo "PASS - Added PDF link section to README"
  fi
else
  echo "Creating new README.md with PDF link"
  cat > README.md <<'EOF'
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
EOF
  echo "PASS - Created README with PDF link"
fi

echo "Integration fix complete!"
