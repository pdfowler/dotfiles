# Shell Completions

This directory is reserved for shell completion management, but completions are now handled by the **bash-completion** system.

## How It Works

Completions are managed automatically using Homebrew's bash-completion system, which works for both bash and zsh:

- **bash-completion**: Installed via `brew install bash-completion`
- **Tool completions**: Added to `$(brew --prefix)/etc/bash_completion.d/`
- **Automatic loading**: Handled by oh-my-zsh (zsh) or bash-completion (bash)

## Current Setup

Completions are managed in: `$(brew --prefix)/etc/bash_completion.d/`

Available completions include:
- kubectl (added manually)
- docker (from Docker Desktop)
- GitHub CLI (from Homebrew)
- Helm, Helmfile, MongoDB CLI, npm, nvm, pipx, etc.

## Management

### Automatic Setup
Completions are set up automatically when you run:
```bash
./install.sh
```

### Manual Management
```bash
# Setup completions for installed tools
completions-setup

# Add completion for a specific tool
add_completion kubectl 'kubectl completion bash'

# Reload completions after installing new tools
completions-reload

# Verify completions are working
verify_completions
```

### Adding New Tools
For tools that support bash-completion:

```bash
# Add completion for any tool that supports it
add_completion <tool_name> '<tool_name> completion bash'

# Examples:
add_completion kubectl 'kubectl completion bash'
add_completion helm 'helm completion bash'
```

## Benefits of bash-completion

- **Standard system**: Uses the industry-standard bash-completion system
- **Cross-shell**: Works with both bash and zsh
- **Automatic management**: Homebrew tools automatically add their completions
- **Centralized**: All completions in one location
- **No custom code**: Leverages existing, well-tested completion system
- **Clean repository**: No generated files in the dotfiles repo

## Troubleshooting

If completions aren't working:

1. **Check bash-completion**: `ls $(brew --prefix)/etc/bash_completion.d/`
2. **Verify tool installation**: `command -v kubectl`
3. **Add missing completion**: `add_completion kubectl 'kubectl completion bash'`
4. **Reload shell**: `exec zsh` or `source ~/.bashrc`
5. **Test completion**: Try `kubectl <TAB>` in a new shell session

## Migration Notes

This system replaced the previous custom completion approach because:
- bash-completion is the standard way to handle completions
- It's automatically managed by Homebrew
- It works consistently across shells
- It requires less custom code maintenance
