#!/bin/bash

# Installer script for mniCoords function
# This script adds the mniCoords function to your shell configuration

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MNICOORDS_SCRIPT="$SCRIPT_DIR/mniCoords.sh"

echo "=== mniCoords Installer ==="
echo ""

# Check if mniCoords.sh exists
if [ ! -f "$MNICOORDS_SCRIPT" ]; then
    echo "Error: mniCoords.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Detect shell configuration file
SHELL_CONFIG=""
if [ -n "$BASH_VERSION" ]; then
    if [ -f "$HOME/.bashrc" ]; then
        SHELL_CONFIG="$HOME/.bashrc"
    elif [ -f "$HOME/.bash_profile" ]; then
        SHELL_CONFIG="$HOME/.bash_profile"
    fi
elif [ -n "$ZSH_VERSION" ]; then
    SHELL_CONFIG="$HOME/.zshrc"
else
    # Try to detect from SHELL variable
    case "$SHELL" in
        */bash)
            if [ -f "$HOME/.bashrc" ]; then
                SHELL_CONFIG="$HOME/.bashrc"
            elif [ -f "$HOME/.bash_profile" ]; then
                SHELL_CONFIG="$HOME/.bash_profile"
            fi
            ;;
        */zsh)
            SHELL_CONFIG="$HOME/.zshrc"
            ;;
        *)
            echo "Could not detect shell type. Please specify your shell config file:"
            echo "Examples: ~/.bashrc, ~/.zshrc, ~/.bash_profile"
            read -r SHELL_CONFIG
            SHELL_CONFIG="${SHELL_CONFIG/#\~/$HOME}"
            ;;
    esac
fi

if [ -z "$SHELL_CONFIG" ]; then
    echo "Error: Could not determine shell configuration file"
    exit 1
fi

echo "Detected shell config: $SHELL_CONFIG"
echo ""

# Check if already installed
SOURCE_LINE="source \"$MNICOORDS_SCRIPT\""
if grep -Fq "$MNICOORDS_SCRIPT" "$SHELL_CONFIG" 2>/dev/null; then
    echo "mniCoords is already installed in $SHELL_CONFIG"
    echo ""
    echo "To reload the function, run:"
    echo "  source $SHELL_CONFIG"
    exit 0
fi

# Add source line to shell config
echo "Adding mniCoords to $SHELL_CONFIG..."
echo "" >> "$SHELL_CONFIG"
echo "# mniCoords - Brain atlas coordinate lookup" >> "$SHELL_CONFIG"
echo "$SOURCE_LINE" >> "$SHELL_CONFIG"

echo ""
echo "✓ Installation complete!"
echo ""
echo "To start using mniCoords, either:"
echo "  1. Run: source $SHELL_CONFIG"
echo "  2. Open a new terminal window"
echo ""
echo "Usage examples:"
echo "  mniCoords 28,-74,20"
echo "  mniCoords 28, -74, 20"
echo "  mniCoords 28 -74 20"
echo ""
