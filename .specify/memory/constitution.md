<!--
Sync Impact Report
- Version change: unversioned template → 1.0.0
- Modified principles: PRINCIPLE_1_NAME → XDG-First Layout; PRINCIPLE_2_NAME → Cross-Shell Parity (Including Non-Interactive); PRINCIPLE_3_NAME → Symlinked Source of Truth; PRINCIPLE_4_NAME → Private Data Isolation; PRINCIPLE_5_NAME → Verified Minimal Changes
- Added sections: Operational Constraints; Development Workflow
- Removed sections: None
- Templates requiring updates: ✅ .specify/templates/plan-template.md; ✅ .specify/templates/spec-template.md; ✅ .specify/templates/tasks-template.md
- Follow-up TODOs: None
-->

# My XDG-Compliant Dotfiles Constitution

## Core Principles

### XDG-First Layout
All configuration files MUST live under XDG-compliant paths (e.g., `~/.config/shell/`) with no new dotfiles added directly to `$HOME`. Each change MUST preserve the clean home directory guarantee and keep related configs grouped by purpose.

### Cross-Shell Parity (Including Non-Interactive)
Shared scripts MUST use POSIX-compatible syntax and run in both zsh and bash. Non-interactive shells MUST inherit required environment via `~/.zshenv` without extra user actions. New features MAY add shell-specific behavior only when isolated in shell-specific files and without breaking parity.

### Symlinked Source of Truth
The repository is the canonical source for configuration. Install flows MUST rely on symlinks back to the repo; manual edits outside the repo are prohibited. Backup/restore steps in install scripts MUST be preserved so users can safely re-run setup.

### Private Data Isolation
Secrets, tokens, and machine-local settings MUST remain outside version control (e.g., `~/.config/shell/private.sh`, `.gitignore` entries). No change may require committing credentials, and review MUST verify secrets stay isolated.

### Verified Minimal Changes
Changes MUST remain minimal, documented in README where behavior shifts, and validated with available scripts (e.g., `test-nvm-fix.sh`, `test-cd-fix.sh`) or new checks when altering shell behavior. Prefer the simplest implementation that satisfies requirements to avoid brittle shell setups.

## Operational Constraints

- Installation MUST continue to work via `install.sh` with idempotent symlink creation and backups of existing configs.
- Environment, PATH, and alias definitions MUST stay separated (`env.sh`, `paths.sh`, `aliases.sh`) to keep responsibilities clear.
- Zsh-specific enhancements MUST live under `config/shell/zsh/` and never block basic non-interactive usage.
- Any new automation MUST avoid introducing dependencies that break in headless or CI environments.

## Development Workflow

1. Design changes in-repo; do not edit symlink targets in place outside the repository.
2. Run relevant test scripts (`test-nvm-fix.sh`, `test-cd-fix.sh`, or new targeted checks) before commit and note outcomes in commit messages when behavior changes.
3. Validate both zsh and bash flows for environment loading; verify non-interactive shells receive expected variables.
4. Document user-facing behavior or setup changes in `README.md` and update install instructions when workflows change.

## Governance

- This constitution supersedes ad-hoc shell practices for this repository. Amendments require updating this file, aligning templates, and documenting migration steps when behavior changes.
- Versioning follows semantic rules: MAJOR for breaking workflow/installation changes, MINOR for new principles or required practices, PATCH for clarifications. Last amended date updates with every change.
- Compliance reviews MUST confirm XDG layout adherence, cross-shell parity, secret isolation, symlink-based installs, and evidence of verification scripts/tests run for behavior changes.

**Version**: 1.0.0 | **Ratified**: 2025-12-09 | **Last Amended**: 2025-12-09
