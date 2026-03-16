#!/usr/bin/env bash
set -u

BASHRC="${HOME}/.bashrc"

START_MARKER="# >>> bashrc.add >>>"
END_MARKER="# <<< bashrc.add <<<"

# Ensure ~/.bashrc exists
touch "$BASHRC" || { echo "Error: cannot write to $BASHRC"; exit 1; }

# If not already added, append the sourcing snippet
if ! grep -Fq "$START_MARKER" "$BASHRC"; then
  cat >> "$BASHRC" <<'EOF'

# >>> bashrc.add >>>
# Load personal bash customizations
if [ -f ~/.bashrc.add ]; then
  source ~/.bashrc.add
fi
# <<< bashrc.add <<<
EOF
  echo "Installed snippet into $BASHRC."
else
  echo "Snippet already in $BASHRC — skipping."
fi

# Deploy .bashrc.add
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE="${SCRIPT_DIR}/.bashrc.add"
DEST="${HOME}/.bashrc.add"

if [ ! -f "$SOURCE" ]; then
  echo "Error: $SOURCE not found."
  exit 1
fi

if [ -f "$DEST" ]; then
  if diff "$SOURCE" "$DEST" > /dev/null 2>&1; then
    echo "$DEST is already up to date."
    exit 0
  else
    echo "Differences between repo and $DEST:"
    diff "$SOURCE" "$DEST"
  fi
fi

cp "$SOURCE" "$DEST"
echo "Copied .bashrc.add to $DEST."
