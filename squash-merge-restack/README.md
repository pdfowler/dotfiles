# Post-Squash-Merge Cleanup Script

## Overview

This script automates the cleanup of stacked branches after multiple branches have been squash-merged into main. It addresses the common problem of rebase conflicts and stack corruption that occurs when using stacked development workflows with squash merges.

## Problem Statement

When using stacked development with Graphite/Charcoal and squash merges, the following issues arise:

- Multiple branches in a stack may be merged via squash commits
- The local stack becomes out of sync with the remote main branch
- Manual rebasing becomes complex and error-prone
- Stack integrity is compromised, leading to merge conflicts

## Requirements

### Constraints

1. **No Forks**: All branches exist in the same repository (no fork-based PRs)
2. **Tracking References**: Local branches have proper tracking references to `origin/branch-name`
3. **Sequential Processing**: Only one branch can be squashed at a time
4. **Stacking Rules**: Only the base branch is ever merged into main (stacking rules are obeyed)
5. **Squash Merges**: All merges to main are performed as squash merges

### Functional Requirements

1. **Multi-Branch Support**: Handle multiple branches in a stack that have been merged
2. **Reverse Matching**: Traverse main branch history to find corresponding local branches
3. **Automatic Detection**: Identify which branches need squashing based on merge commits
4. **Stack Preservation**: Maintain stack integrity throughout the process
5. **Error Handling**: Gracefully handle missing branches or failed operations

## Proposed Algorithm

### Phase 1: Discovery

1. **Navigate to Stack Bottom**: Use `gt branch bottom` to move to the first branch from trunk
2. **Find Merge Base**: Determine the common ancestor between current stack and main
3. **Identify Merge Commits**: Traverse main branch history since merge base to find squash merge commits
4. **Extract PR Information**: Parse commit messages to identify associated PR numbers

### Phase 2: Branch Mapping

1. **PR to Branch Resolution**: Use GitHub CLI to map PR numbers to head branch names
2. **Local Branch Discovery**: Find local branches that track the corresponding remote branches
3. **Stack Validation**: Ensure discovered branches are part of the current stack
4. **Ordering**: Process branches in chronological order of their merge commits

### Phase 3: Sequential Processing

1. **Branch Selection**: Switch to each identified branch in sequence
2. **Rebase onto Squash Commit**: Rebase the branch onto its corresponding squash merge commit
3. **Squash Operation**: Use `gt branch squash` to consolidate commits and restack dependent branches
4. **Stack Integrity**: Verify stack remains intact after each operation

### Phase 4: Finalization

1. **Complete Restack**: Use `gt stack restack` to ensure all branches are properly aligned
2. **Sync with Main**: Use `gt repo sync` to pull latest changes and clean up merged branches
3. **Validation**: Verify the final state of the stack

## Implementation Strategy

### Core Operations

- **Branch Navigation**: `gt branch bottom` to start from stack base
- **History Traversal**: `git log --merges --reverse` to find merge commits chronologically
- **PR Resolution**: `gh pr view` to get branch information from PR numbers
- **Branch Matching**: `git branch -vv` to find local branches with tracking references
- **Rebase Operations**: `git rebase` to align branches with squash commits
- **Squash Operations**: `gt branch squash` to consolidate commits
- **Stack Management**: `gt stack restack` to maintain stack integrity
- **Synchronization**: `gt repo sync` to sync with remote main

### Error Handling

- **Missing Branches**: Skip branches that don't exist locally
- **Failed Rebases**: Provide clear error messages and stop execution
- **Stack Corruption**: Validate stack integrity after each operation
- **PR Resolution Failures**: Handle cases where PR information cannot be extracted

### Safety Features

- **Dry Run Mode**: Preview operations without executing them
- **Interactive Confirmation**: Allow user confirmation for each major operation
- **Detailed Logging**: Provide comprehensive output for debugging
- **Rollback Capability**: Maintain ability to undo operations if needed

## Usage Scenarios

### Single Branch Cleanup

When only one branch in a stack has been merged, the script simplifies to basic squash and restack operations.

### Multi-Branch Cleanup

When multiple branches have been merged, the script processes them sequentially, maintaining stack integrity throughout.

### Partial Stack Cleanup

When some branches in a stack remain unmerged, the script handles only the merged branches and preserves the rest.

## Benefits

1. **Automation**: Eliminates manual rebase operations and reduces human error
2. **Stack Integrity**: Maintains proper branch relationships throughout the process
3. **Scalability**: Handles complex stacks with multiple merged branches
4. **Reliability**: Provides consistent results across different scenarios
5. **Time Savings**: Reduces the time spent on post-merge cleanup operations

## Future Enhancements

- **Integration with CI/CD**: Automate cleanup as part of deployment pipelines
- **Custom Configuration**: Allow configuration of merge detection strategies
- **Advanced Branch Matching**: Support for more sophisticated branch name matching
- **Performance Optimization**: Parallel processing where possible
- **Integration with Other Tools**: Support for alternative Git workflow tools

## Dependencies

- **Charcoal CLI**: For stack management operations
- **GitHub CLI**: For PR information retrieval
- **Git**: For core Git operations
- **Bash**: For script execution environment

## Testing Strategy

- **Unit Testing**: Test individual components in isolation
- **Integration Testing**: Test with real repository scenarios
- **Edge Case Testing**: Handle various failure modes and edge cases
- **Performance Testing**: Ensure reasonable execution times for large stacks
- **User Acceptance Testing**: Validate with actual development workflows
