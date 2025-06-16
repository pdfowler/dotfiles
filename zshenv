# ~/.zshenv - Always sourced by zsh (login, interactive, non-interactive)
# This is the key for making configurations available to non-interactive shells

# Source cross-shell compatible configurations
[[ -f ~/.config/shell/env.sh ]] && source ~/.config/shell/env.sh
[[ -f ~/.config/shell/paths.sh ]] && source ~/.config/shell/paths.sh

# Only load aliases in interactive shells (they can cause issues in scripts)
[[ -n "$PS1" ]] && [[ -f ~/.config/shell/aliases.sh ]] && source ~/.config/shell/aliases.sh 