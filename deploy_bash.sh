#!/usr/bin/env bash
set -u

BASHRC="${HOME}/.bashrc"

START_MARKER="# >>> bashrc.add >>>"
END_MARKER="# <<< bashrc.add <<<"

# Ensure ~/.bashrc exists
touch "$BASHRC" || { echo "Error: cannot write to $BASHRC"; exit 1; }

# If already added, do nothing
if grep -Fq "$START_MARKER" "$BASHRC"; then
  echo "Already installed in $BASHRC — nothing to do."
  exit 0
fi

# Append block
cat >> "$BASHRC" <<'EOF'

# >>> bashrc.add >>>
# Load personal bash customizations
if [ -f ~/.bashrc.add ]; then
  source ~/.bashrc.add
fi
# <<< bashrc.add <<<
EOF

echo "Installed snippet into $BASHRC."
