#!/usr/bin/env bash
set -euo pipefail

# ────────────────────────────────────────────────────────────
# SOPS Setup Script
# ────────────────────────────────────────────────────────────
# This script helps set up SOPS for the first time
# Run after: nix switch (to install sops and age)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SOPS_DIR="$HOME/.config/sops/age"
AGE_KEY_FILE="$SOPS_DIR/keys.txt"
SOPS_CONFIG="$CONFIG_DIR/.sops.yaml"
SECRETS_DIR="$CONFIG_DIR/secrets"
OLD_SECRETS_DIR="$HOME/.config/secrets"

echo "🔐 SOPS Setup for NixOS"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Step 1: Check if tools are installed
echo -n "Checking for required tools... "
if ! command -v age &> /dev/null; then
    echo "❌"
    echo "Error: 'age' not found. Please run 'nix develop' or install age first."
    exit 1
fi
if ! command -v sops &> /dev/null; then
    echo "❌"
    echo "Error: 'sops' not found. Please run 'nix develop' or install sops first."
    exit 1
fi
echo "✅"

# Step 2: Generate age key if needed
if [ ! -f "$AGE_KEY_FILE" ]; then
    echo "Generating new age key..."
    mkdir -p "$SOPS_DIR"
    age-keygen -o "$AGE_KEY_FILE"
    chmod 600 "$AGE_KEY_FILE"
    echo "✅ Age key generated at: $AGE_KEY_FILE"
else
    echo "✅ Age key already exists at: $AGE_KEY_FILE"
fi

# Step 3: Display public key
echo ""
echo "📋 Your age public key (add this to .sops.yaml):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
AGE_PUBLIC_KEY=$(age-keygen -y "$AGE_KEY_FILE")
echo "$AGE_PUBLIC_KEY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Step 4: Update .sops.yaml
echo -n "Updating .sops.yaml with your public key... "
if grep -q "YOUR_AGE_PUBLIC_KEY_WILL_BE_GENERATED" "$SOPS_CONFIG" 2>/dev/null; then
    # Extract just the key part (after 'age1')
    KEY_PART="${AGE_PUBLIC_KEY#age}"
    sed -i.bak "s/age1<YOUR_AGE_PUBLIC_KEY_WILL_BE_GENERATED>/age${KEY_PART}/g" "$SOPS_CONFIG"
    rm -f "${SOPS_CONFIG}.bak"
    echo "✅"
else
    echo "⏭️  (already configured)"
fi

# Step 5: Create initial secrets file if it doesn't exist
mkdir -p "$SECRETS_DIR"

SECRETS_FILE="$SECRETS_DIR/secrets.yaml"
if [ ! -f "$SECRETS_FILE" ]; then
    echo "Creating initial encrypted secrets file..."
    # Create initial structure
    cat > "$SECRETS_FILE.tmp" <<EOF
# Encrypted secrets for NixOS
# Edit with: sops secrets/secrets.yaml

# Example secrets - replace with your actual values
# github-token: REPLACE_WITH_YOUR_TOKEN
# api-key: REPLACE_WITH_YOUR_API_KEY
EOF

    # Encrypt the file
    sops --encrypt --age "$AGE_PUBLIC_KEY" "$SECRETS_FILE.tmp" > "$SECRETS_FILE"
    rm "$SECRETS_FILE.tmp"
    echo "✅ Created encrypted secrets file: $SECRETS_FILE"
    echo "   Edit with: sops $SECRETS_FILE"
else
    echo "✅ Secrets file already exists: $SECRETS_FILE"
fi

# Step 6: Migrate existing plaintext secrets
echo ""
echo "🔄 Checking for existing plaintext secrets to migrate..."

if [ -d "$OLD_SECRETS_DIR" ]; then
    echo "Found plaintext secrets in: $OLD_SECRETS_DIR"

    for secret_file in "$OLD_SECRETS_DIR"/*; do
        if [ -f "$secret_file" ]; then
            filename=$(basename "$secret_file")
            echo "  📄 $filename"
 
            # Read the plaintext value
            secret_value=$(cat "$secret_file" | tr -d '\n')

            # Prompt user to add to encrypted file
            echo "     Value found. After running this script, edit the encrypted file and add:"
            echo "     $filename: $secret_value"
        fi
    done

    echo ""
    echo "⚠️  After migrating values, you can safely delete: $OLD_SECRETS_DIR"
    echo "   The encrypted values will be decrypted to the same location by home-manager"
else
    echo "No existing plaintext secrets directory found."
fi

# Step 7: Final instructions
echo ""
echo "✅ SOPS setup complete!"
echo ""
echo "Next steps:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "1. Edit the encrypted secrets file:"
echo "   sops $SECRETS_FILE"
echo ""
echo "2. Add your actual secret values"
echo ""
echo "3. Run 'nix switch' or rebuild to apply the configuration"
echo "   Secrets will be decrypted to ~/.config/secrets/"
echo ""
echo "4. Verify secrets are available:"
echo "   ls -la ~/.config/secrets/"
echo ""
echo "Useful commands:"
echo "  sops secrets/secrets.yaml  # Edit encrypted secrets"
echo "  age-keygen -y ~/.config/sops/age/keys.txt  # Show your age public key"
echo ""
