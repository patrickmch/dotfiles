#!/bin/bash
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

DOTFILES_DIR="$HOME/dotfiles"

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if dotfiles directory exists
if [ ! -d "$DOTFILES_DIR" ]; then
    error "Dotfiles directory not found at $DOTFILES_DIR"
    error "Please clone the repo to ~/dotfiles first"
    exit 1
fi

# Create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"

    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
            info "Already linked: $target"
            return
        fi
        warn "Backing up existing $target to ${target}.backup"
        mv "$target" "${target}.backup"
    fi

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    ln -s "$source" "$target"
    info "Linked: $target -> $source"
}

# ============================================
# Homebrew
# ============================================
install_homebrew() {
    if command -v brew &> /dev/null; then
        info "Homebrew already installed"
    else
        info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

        # Add Homebrew to PATH for Apple Silicon Macs
        if [ -f "/opt/homebrew/bin/brew" ]; then
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
}

# ============================================
# Brew packages
# ============================================
install_brew_packages() {
    info "Installing Homebrew packages..."

    brew install zsh || true
    brew install git || true
    brew install neovim || true
    brew install zplug || true
    brew install nvm || true
    brew install direnv || true
    brew install --HEAD universal-ctags/universal-ctags/universal-ctags || true

    # Casks (GUI apps)
    brew install --cask karabiner-elements || true
    brew install --cask iterm2 || true
}

# ============================================
# Oh My Zsh
# ============================================
install_oh_my_zsh() {
    if [ -d "$HOME/.oh-my-zsh" ]; then
        info "Oh My Zsh already installed"
    else
        info "Installing Oh My Zsh..."
        sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
    fi

    # Install Powerlevel9k/Powerlevel10k theme
    local theme_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel9k"
    if [ ! -d "$theme_dir" ]; then
        info "Installing Powerlevel9k theme..."
        git clone https://github.com/Powerlevel9k/powerlevel9k.git "$theme_dir"
    fi
}

# ============================================
# Symlinks
# ============================================
create_symlinks() {
    info "Creating symlinks..."

    # Shell
    create_symlink "$DOTFILES_DIR/zsh/.zshrc" "$HOME/.zshrc"
    create_symlink "$DOTFILES_DIR/zsh/.powerlevel_config" "$HOME/.powerlevel_config"
    create_symlink "$DOTFILES_DIR/zsh/.zsh_theme_config" "$HOME/.zsh_theme_config"

    # Vim / Neovim
    create_symlink "$DOTFILES_DIR/vimrcs/.vimrc" "$HOME/.vimrc"
    create_symlink "$DOTFILES_DIR/.config/nvim" "$HOME/.config/nvim"

    # Karabiner
    create_symlink "$DOTFILES_DIR/.config/karabiner" "$HOME/.config/karabiner"

    # Python tools
    create_symlink "$DOTFILES_DIR/python/.pdbrc.py" "$HOME/.pdbrc.py"
    create_symlink "$DOTFILES_DIR/python/.pythonrc" "$HOME/.pythonrc"
    create_symlink "$DOTFILES_DIR/.ipython" "$HOME/.ipython"
    create_symlink "$DOTFILES_DIR/.jupyter" "$HOME/.jupyter"
    create_symlink "$DOTFILES_DIR/.config/pudb" "$HOME/.config/pudb"
    create_symlink "$DOTFILES_DIR/.config/bpython" "$HOME/.config/bpython"
    create_symlink "$DOTFILES_DIR/.config/pycodestyle" "$HOME/.config/pycodestyle"

    # Direnv
    create_symlink "$DOTFILES_DIR/.direnvrc" "$HOME/.direnvrc"

    # Slate (window manager)
    create_symlink "$DOTFILES_DIR/.slate" "$HOME/.slate"

    # ESLint
    create_symlink "$DOTFILES_DIR/.elintrc.json" "$HOME/.eslintrc.json"

    # SSH
    create_symlink "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
}

# ============================================
# Fonts
# ============================================
install_fonts() {
    info "Installing fonts..."

    local font_dir="$HOME/Library/Fonts"
    mkdir -p "$font_dir"

    if [ -d "$DOTFILES_DIR/fonts" ]; then
        cp -n "$DOTFILES_DIR/fonts/"* "$font_dir/" 2>/dev/null || true
        info "Fonts installed to $font_dir"
    else
        warn "No fonts directory found"
    fi
}

# ============================================
# Git ctags hooks
# ============================================
setup_git_ctags() {
    info "Setting up git ctags hooks..."

    git config --global init.templatedir "$HOME/.git_template"
    mkdir -p "$HOME/.git_template/hooks"

    # Main ctags hook
    cat > "$HOME/.git_template/hooks/ctags" << 'EOF'
#!/bin/sh
set -e
PATH="/usr/local/bin:/opt/homebrew/bin:$PATH"
dir="$(git rev-parse --git-dir)"
trap 'rm -f "$dir/$$.tags"' EXIT
git ls-files | ctags --tag-relative -L - -f"$dir/$$.tags"
mv "$dir/$$.tags" "$dir/tags"
EOF
    chmod +x "$HOME/.git_template/hooks/ctags"

    # Post hooks that trigger ctags
    for hook in post-commit post-merge post-checkout; do
        cat > "$HOME/.git_template/hooks/$hook" << 'EOF'
#!/bin/sh
.git/hooks/ctags >/dev/null 2>&1 &
EOF
        chmod +x "$HOME/.git_template/hooks/$hook"
    done

    # Post-rewrite hook
    cat > "$HOME/.git_template/hooks/post-rewrite" << 'EOF'
#!/bin/sh
case "$1" in
  rebase) exec .git/hooks/post-merge ;;
esac
EOF
    chmod +x "$HOME/.git_template/hooks/post-rewrite"

    info "Git ctags hooks configured"
}

# ============================================
# Set default shell
# ============================================
set_default_shell() {
    local zsh_path

    # Find zsh path (different on Intel vs Apple Silicon)
    if [ -f "/opt/homebrew/bin/zsh" ]; then
        zsh_path="/opt/homebrew/bin/zsh"
    elif [ -f "/usr/local/bin/zsh" ]; then
        zsh_path="/usr/local/bin/zsh"
    else
        zsh_path="$(which zsh)"
    fi

    if [ "$SHELL" = "$zsh_path" ]; then
        info "Zsh is already the default shell"
    else
        info "Setting zsh as default shell..."
        if ! grep -q "$zsh_path" /etc/shells; then
            warn "Adding $zsh_path to /etc/shells (requires sudo)"
            echo "$zsh_path" | sudo tee -a /etc/shells
        fi
        chsh -s "$zsh_path"
        info "Default shell changed to zsh"
    fi
}

# ============================================
# Main
# ============================================
main() {
    echo ""
    echo "========================================"
    echo "       Dotfiles Installation"
    echo "========================================"
    echo ""

    install_homebrew
    install_brew_packages
    install_oh_my_zsh
    create_symlinks
    install_fonts
    setup_git_ctags
    set_default_shell

    echo ""
    echo "========================================"
    info "Installation complete!"
    echo "========================================"
    echo ""
    warn "Please restart your terminal or run: source ~/.zshrc"
    echo ""
}

main "$@"
