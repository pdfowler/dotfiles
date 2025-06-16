# Cross-shell compatible aliases and functions
# Works in both bash and zsh

# Basic aliases
alias ll="ls -la" # long list
alias la="ls -A"  # list all except . and ..
alias lc="ls -CF"  # list in columns
alias grep="grep --color=auto"
alias fgrep="fgrep --color=auto"
alias egrep="egrep --color=auto"

# Editor shortcuts
alias v="$EDITOR"

# Directory navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"
alias -- -="cd -"

settings() {
  case "$SHELL" in
    */zsh)
      $EDITOR ~/.zshrc
      ;;
    */bash)
      $EDITOR ~/.bashrc
      ;;
    *)
      echo "Unknown shell: $SHELL"
      ;;
  esac
}

# Utility functions (cross-shell compatible)
update() {
    case "$SHELL" in
        */zsh)
            echo "Reloading zsh configuration..."
            source ~/.zshenv
            source ~/.zshrc
            ;;
        */bash)
            echo "Reloading bash configuration..."
            source ~/.bashrc
            ;;
        *)
            echo "Unknown shell: $SHELL"
            ;;
    esac
}

# Aliases for Shiftsmart Repos
cd() {
  if [[ "$1" == @* ]]; then
    case "$1" in
      @shiftsmart)
        local path="$SHIFTSMART_ROOT"
        ;;
      @ssm/*)
        local sub="${1#@ssm/}"
        local path="$SHIFTSMART_ROOT/services/ssm/packages/$sub"
        ;;
      @monorepo/packages/*)
        local sub="${1#@monorepo/packages/}"
        local path="$SHIFTSMART_ROOT/services/monorepo/packages/$sub"
        ;;
      @monorepo/applications/*)
        local sub="${1#@monorepo/applications/}"
        local path="$SHIFTSMART_ROOT/services/monorepo/applications/$sub"
        ;;
      @monorepo/*)
        local sub="${1#@monorepo/}"
        local path="$SHIFTSMART_ROOT/services/monorepo/packages/$sub"
        ;;
      @*)
        local dir="${1#@}"
        local path="$SHIFTSMART_ROOT/services/$dir"
        ;;
    esac
    if [[ -d "$path" ]]; then
      echo "Changing to $path"
      builtin cd "$path"
    else
      echo "Directory not found: $path"
      return 1
    fi
    return
  fi
  builtin cd "$@"
}

# Find and kill process by name
killall_grep() {
    ps aux | grep "$1" | grep -v grep | awk '{print $2}' | xargs kill -9
} 

# Find and kill process by port
killall_port() {
    lsof -i :$1 | awk 'NR>1 {print $2}' | xargs kill -9
}