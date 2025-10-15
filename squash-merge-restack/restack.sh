#!/bin/bash
# GT Stack Sync - Post-Squash-Merge Cleanup Script
# Automates cleanup of stacked branches after multiple squash merges
#
# How it works:
#   1. Scans ALL merge commits on main since your stack diverged
#   2. For each merge, checks if you have that branch locally AND in your current stack
#   3. Only processes branches that match both criteria
#   4. Squashes and rebases matching branches onto their merge commits
#   5. Cleans up branches that are now identical to main
#   6. Restacks remaining branches
#
# Why it scans so many commits:
#   The script needs to check every merge on main to see if any correspond to your
#   local stack branches. Most will be skipped (no local branch or not in stack).
#   This is normal and expected - don't worry about the "skipped" count.
#
# Fail-fast behavior:
#   If ANY branch processing fails (e.g., merge conflicts), the script will STOP
#   immediately to prevent cascading issues. Resolve conflicts and rerun.

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if gt command is available
check_gt_command() {
    if ! command -v gt &> /dev/null; then
        log_error "gt command not found. Please install Charcoal CLI first."
        log_info "Visit: https://docs.graphite.dev/guides/graphite-cli"
        exit 1
    fi
    log_success "gt command found"
}

# Check if gh command is available
check_gh_command() {
    if ! command -v gh &> /dev/null; then
        log_error "gh command not found. Please install GitHub CLI first."
        log_info "Visit: https://cli.github.com/"
        exit 1
    fi
    log_success "gh command found"
}

# Check if we're in a git repository
check_git_repo() {
    if ! git rev-parse --git-dir > /dev/null 2>&1; then
        log_error "Not in a git repository"
        exit 1
    fi
    log_success "Git repository detected"
}

# Check if we're on a tracked branch
check_tracked_branch() {
    # Check if we're in the middle of a rebase
    if git rev-parse --git-dir > /dev/null 2>&1 && [ -d "$(git rev-parse --git-dir)/rebase-merge" ]; then
        log_error "Currently in the middle of a rebase. Please resolve conflicts and run 'gt continue' or abort with 'gt rebase --abort'"
        exit 1
    fi
    
    if ! gt branch info > /dev/null 2>&1; then
        log_error "Current branch is not tracked by Charcoal. Please run 'gt branch track' first."
        exit 1
    fi
    log_success "Current branch is tracked by Charcoal"
}

# Get current branch name
get_current_branch() {
    gt branch info --format="%n" 2>/dev/null || git branch --show-current
}

# Navigate to bottom of stack
navigate_to_bottom() {
    log_info "Navigating to bottom of stack..." >&2
    gt branch bottom >&2
    local bottom_branch=$(get_current_branch)
    log_success "At bottom of stack: $bottom_branch" >&2
    echo "$bottom_branch"
}

# Find merge base with main
find_merge_base() {
    local merge_base=$(git merge-base HEAD main 2>/dev/null || git merge-base HEAD origin/main)
    log_info "Merge base with main: $merge_base" >&2  # Redirect to stderr so it doesn't pollute return value
    echo "$merge_base"
}

# Get merge commits on main since merge base
# Note: We look for ALL commits (not just --merges) because squash-merge creates regular commits
get_merge_commits() {
    local merge_base="$1"
    local merge_commits
    
    # Try to get commits from origin/main (squash merges are regular commits, not merge commits)
    if git rev-parse --verify origin/main > /dev/null 2>&1; then
        merge_commits=$(git log --oneline --reverse "$merge_base"..origin/main 2>/dev/null || echo "")
    else
        # Fallback to local main
        merge_commits=$(git log --oneline --reverse "$merge_base"..main 2>/dev/null || echo "")
    fi
    
    if [ -z "$merge_commits" ]; then
        log_info "No commits found on main since merge base (stack is up to date)" >&2
        return 1
    fi
    
    log_info "Found commits on main since merge base:" >&2
    echo "$merge_commits" | while read -r commit; do
        log_info "  $commit" >&2
    done
    
    echo "$merge_commits"
}

# Extract PR number from commit message
extract_pr_number() {
    local commit_sha="$1"
    local commit_message=$(git log --format=%B -n 1 "$commit_sha")
    
    # Look for PR number in various formats
    local pr_number=$(echo "$commit_message" | grep -oE "(#[0-9]+|PR #[0-9]+|Merge pull request #[0-9]+)" | grep -oE "[0-9]+" | head -1)
    
    if [ -n "$pr_number" ]; then
        echo "$pr_number"
    else
        return 1
    fi
}

# Get PR head branch from GitHub
get_pr_head_branch() {
    local pr_number="$1"
    local pr_head
    
    if pr_head=$(gh pr view "$pr_number" --json headRefName --jq '.headRefName' 2>/dev/null); then
        echo "$pr_head"
    else
        return 1
    fi
}

# Find local branch tracking the remote branch
find_local_branch() {
    local remote_branch="$1"
    local local_branch
    
    # Try exact match first - use awk for robust parsing
    # git branch -vv format: "* branch-name  commit-sha [origin/branch-name] msg"
    local_branch=$(git branch -vv | grep "\[origin/$remote_branch\]" | awk '{if ($1 == "*") print $2; else print $1}' | head -1)
    
    # If no exact match, try partial match
    if [ -z "$local_branch" ]; then
        local_branch=$(git branch -vv | grep "origin/$remote_branch" | awk '{if ($1 == "*") print $2; else print $1}' | head -1)
    fi
    
    if [ -n "$local_branch" ]; then
        echo "$local_branch"
    else
        return 1
    fi
}

# Check if branch is part of current stack
is_branch_in_stack() {
    local branch_name="$1"
    
    # Get current stack info (use --stack to scope to current stack only)
    local stack_info=$(gt log --stack --quiet 2>/dev/null || echo "")
    
    if echo "$stack_info" | grep -q "$branch_name"; then
        return 0
    else
        return 1
    fi
}

# Check if branch has the same SHA as main
branch_equals_main() {
    local branch_name="$1"
    local main_sha=$(git rev-parse main 2>/dev/null || git rev-parse origin/main)
    local branch_sha=$(git rev-parse "$branch_name" 2>/dev/null)
    
    if [[ "$branch_sha" == "$main_sha" ]]; then
        log_info "Branch $branch_name has same SHA as main: $branch_sha"
        return 0
    else
        return 1
    fi
}

# Check if branch has no commits (empty branch)
branch_is_empty() {
    local branch_name="$1"
    local main_sha=$(git rev-parse main 2>/dev/null || git rev-parse origin/main)
    local branch_sha=$(git rev-parse "$branch_name" 2>/dev/null)
    local merge_base=$(git merge-base "$branch_sha" "$main_sha")
    
    # If the branch SHA equals the merge base, it has no unique commits
    if [[ "$branch_sha" == "$merge_base" ]]; then
        log_info "Branch $branch_name has no unique commits"
        return 0
    else
        return 1
    fi
}

# Remove branch from stack using gt branch unbranch or untrack
remove_branch_from_stack() {
    local branch_name="$1"
    local current_branch=$(get_current_branch)
    
    # Check if we're currently on the branch that needs to be removed
    if [[ "$current_branch" == "$branch_name" ]]; then
        log_info "Currently on branch $branch_name, using gt branch unbranch..."
        
        # Use gt branch unbranch to remove the current branch
        if gt branch unbranch; then
            log_success "Successfully unbrached current branch $branch_name"
        else
            log_error "Failed to unbranch current branch $branch_name"
            return 1
        fi
    else
        log_info "Switching to branch $branch_name before removing..."
        
        # Switch to the branch first
        if ! gt branch checkout "$branch_name"; then
            log_error "Failed to checkout branch $branch_name"
            return 1
        fi
        
        # Try to go "up" to the parent branch if possible
        log_info "Attempting to navigate up from $branch_name..."
        if gt branch up 2>/dev/null; then
            log_success "Navigated up to parent branch"
        else
            log_info "Could not navigate up, staying on $branch_name"
        fi
        
        # Now remove the branch
        log_info "Removing branch $branch_name..."
        if gt branch untrack "$branch_name"; then
            log_success "Successfully untracked branch $branch_name"
            
            # Checkout another branch before deleting the local branch (use --stack to scope to current stack only)
            local other_branch=$(gt log --stack --quiet 2>/dev/null | grep -E "[[:space:]]*◯|[[:space:]]*◉" | sed 's/^[[:space:]]*[◯◉][[:space:]]*//' | sed 's/^[[:space:]]*│[[:space:]]*[◯◉][[:space:]]*//' | sed 's/[[:space:]]*│.*$//' | sed 's/[[:space:]]*(current).*$//' | sed 's/[[:space:]]*(needs restack).*$//' | sed 's/[[:space:]]*$//' | grep -v "^main$" | grep -v "^$branch_name$" | head -1)
            
            if [ -n "$other_branch" ]; then
                log_info "Checking out $other_branch before deleting $branch_name..."
                gt branch checkout "$other_branch" 2>/dev/null || true
            fi
            
            # Delete the local branch
            if git branch -D "$branch_name"; then
                log_success "Successfully deleted local branch $branch_name"
            else
                log_warning "Failed to delete local branch $branch_name"
            fi
        else
            log_error "Failed to untrack branch $branch_name"
            return 1
        fi
    fi
    
    return 0
}

# Clean up branches that are identical to main or empty
cleanup_identical_branches() {
    log_info "Checking for branches identical to main or empty..."
    
    # Get all branches in current stack (use --stack to scope to current stack only)
    local stack_branches=$(gt log --stack --quiet 2>/dev/null | grep -E "[[:space:]]*◯|[[:space:]]*◉" | sed 's/^[[:space:]]*[◯◉][[:space:]]*//' | sed 's/^[[:space:]]*│[[:space:]]*[◯◉][[:space:]]*//' | sed 's/[[:space:]]*│.*$//' | sed 's/[[:space:]]*(current).*$//' | sed 's/[[:space:]]*(needs restack).*$//' | sed 's/[[:space:]]*$//' | grep -v "^main$" || echo "")
    
    if [ -z "$stack_branches" ]; then
        log_info "No branches found in stack to check"
        return 0
    fi
    
    log_info "Found branches to check: $stack_branches"
    
    local removed_count=0
    while IFS= read -r branch_name; do
        if [ -z "$branch_name" ]; then
            continue
        fi
        
        # Clean up the branch name (remove any remaining artifacts)
        branch_name=$(echo "$branch_name" | sed 's/ *(current).*$//' | sed 's/ *(needs restack).*$//' | sed 's/ *$//')
        
        log_info "Checking branch: '$branch_name'"
        
        # Check if branch exists locally
        if ! git show-ref --verify --quiet "refs/heads/$branch_name"; then
            log_warning "Branch $branch_name not found locally, skipping"
            continue
        fi
        
        # Check if branch is identical to main or empty
        if branch_equals_main "$branch_name" || branch_is_empty "$branch_name"; then
            log_info "Branch $branch_name is identical to main or empty, removing..."
            if remove_branch_from_stack "$branch_name"; then
                ((removed_count++))
            fi
        else
            log_info "Branch $branch_name is not identical to main and not empty, keeping"
        fi
        
    done <<< "$stack_branches"
    
    if [ $removed_count -gt 0 ]; then
        log_success "Removed $removed_count identical/empty branches"
        return 0
    else
        log_info "No identical or empty branches found"
        return 0
    fi
}

# Process a single merge commit
process_merge_commit() {
    local commit_sha="$1"
    local commit_line="$2"
    
    # Note: No logging here - progress is shown by caller with inline updates
    
    # Extract PR number
    local pr_number
    if ! pr_number=$(extract_pr_number "$commit_sha"); then
        # Silently skip - will be counted in summary
        return 0
    fi
    
    # Get PR head branch
    local pr_head
    if ! pr_head=$(get_pr_head_branch "$pr_number"); then
        # Silently skip - will be counted in summary
        return 0
    fi
    
    # Find local branch
    local local_branch
    if ! local_branch=$(find_local_branch "$pr_head"); then
        # Silently skip - will be counted in summary
        return 0
    fi
    
    # Check if branch is in current stack
    if ! is_branch_in_stack "$local_branch"; then
        # Silently skip - not in our stack
        return 0
    fi
    
    # If we get here, this branch is in our stack and needs processing
    # Note: Caller will clear the progress line before we print
    log_success "Found branch in current stack: $local_branch (PR #$pr_number)"
    
    # Switch to the branch
    log_info "Switching to branch: $local_branch"
    gt branch checkout "$local_branch"
    
    # Rebase onto the squash merge commit
    log_info "Rebasing $local_branch onto $commit_sha"
    if git rebase "$commit_sha"; then
        log_success "Successfully rebased $local_branch onto $commit_sha"
    else
        log_error "Failed to rebase $local_branch onto $commit_sha"
        log_info "You may need to resolve conflicts manually and run 'git rebase --continue'"
        return 1
    fi
    
    # Squash the branch
    log_info "Squashing branch: $local_branch"
    if gt branch squash; then
        log_success "Successfully squashed $local_branch"
    else
        log_error "Failed to squash $local_branch"
        return 1
    fi
    
    return 0
}

# Navigate back to original branch or bottom of stack
navigate_back_to_original_or_bottom() {
    local original_branch="$1"
    
    log_info "Navigating back to appropriate branch..."
    
    # Check if the original branch still exists and is tracked
    if git show-ref --verify --quiet "refs/heads/$original_branch" 2>/dev/null; then
        # Check if it's still tracked by Charcoal
        if gt branch checkout "$original_branch" 2>/dev/null; then
            log_success "Returned to original branch: $original_branch"
            return 0
        else
            log_warning "Original branch $original_branch exists but is not tracked by Charcoal"
        fi
    else
        log_info "Original branch $original_branch no longer exists"
    fi
    
    # If we can't go back to original branch, go to bottom of stack
    log_info "Navigating to bottom of stack..."
    if gt branch bottom; then
        local bottom_branch=$(get_current_branch)
        log_success "Navigated to bottom of stack: $bottom_branch"
    else
        log_warning "Could not navigate to bottom of stack, staying on current branch"
    fi
}

# Main cleanup function
main_cleanup() {
    log_info "Starting post-squash-merge cleanup..."
    
    # Remember the original branch we started on
    local original_branch=$(get_current_branch)
    log_info "Starting from branch: $original_branch"
    
    # Abort any existing rebase
    if git rev-parse --git-dir > /dev/null 2>&1 && [ -d "$(git rev-parse --git-dir)/rebase-merge" ]; then
        log_info "Aborting existing rebase..."
        git rebase --abort 2>/dev/null || true
    fi
    
    # Fetch latest changes from origin/main (without merging)
    log_info "Fetching latest changes from origin/main..."
    if git fetch origin main; then
        log_success "Successfully fetched latest changes from origin/main"
    else
        log_warning "Failed to fetch from origin/main, continuing anyway"
    fi
    
    # Navigate to bottom of stack
    local bottom_branch
    bottom_branch=$(navigate_to_bottom)
    
    # Find merge base
    local merge_base
    merge_base=$(find_merge_base)
    
    # Get commits on main (looking for squash-merged PRs)
    local merge_commits
    if ! merge_commits=$(get_merge_commits "$merge_base"); then
        log_info "No commits to process (stack is up to date with main)."
    else
        local total_commits=$(echo "$merge_commits" | wc -l | tr -d ' ')
        log_info "Found $total_commits commits on origin/main since stack diverged"
        log_info "Scanning for squash-merged PRs that match branches in current stack..."
        echo "" # Blank line for the progress indicator
        
        # Process each merge commit
        local processed_count=0
        local checked_count=0
        while IFS= read -r commit_line; do
            if [ -z "$commit_line" ]; then
                continue
            fi
            
            local commit_sha=$(echo "$commit_line" | cut -d' ' -f1)
            ((checked_count++))
            
            # Show progress on same line (will be cleared if branch is found)
            printf "\r${BLUE}[SCAN]${NC} Checking merge commit %d/%d on origin/main...  " "$checked_count" "$total_commits"
            
            # FAIL-FAST: If processing fails, stop immediately
            if process_merge_commit "$commit_sha" "$commit_line"; then
                # Clear the progress line before showing success message
                printf "\r\033[K"
                ((processed_count++))
            else
                local exit_code=$?
                # Clear the progress line
                printf "\r\033[K"
                
                if [ $exit_code -ne 0 ]; then
                    # Non-zero return means actual failure
                    log_error "Failed to process merge commit $commit_sha"
                    log_error "Stopping to prevent further issues. Repository may be in an inconsistent state."
                    log_info "To continue, resolve any conflicts and rerun this script."
                    exit 1
                fi
                # If exit_code is 0, it was just skipped (no action needed)
            fi
            
        done <<< "$merge_commits"
        
        # Clear the progress line and show final summary
        printf "\r\033[K"
        local skipped_count=$((total_commits - processed_count))
        log_success "Scanned $total_commits merge commits on origin/main: processed $processed_count, skipped $skipped_count"
    fi
    
    # Always clean up branches that are identical to main or empty
    cleanup_identical_branches
    
    # Final restack - ensure we're on a tracked branch first
    log_info "Performing final restack..."
    
    # Check if current branch is tracked, if not, checkout a tracked branch
    if ! gt branch info > /dev/null 2>&1; then
        log_info "Current branch is not tracked, finding a tracked branch to checkout..."
        local tracked_branch=$(gt log --stack --quiet 2>/dev/null | grep -E "[[:space:]]*◯|[[:space:]]*◉" | sed 's/^[[:space:]]*[◯◉][[:space:]]*//' | sed 's/^[[:space:]]*│[[:space:]]*[◯◉][[:space:]]*//' | sed 's/[[:space:]]*│.*$//' | sed 's/[[:space:]]*(current).*$//' | sed 's/[[:space:]]*(needs restack).*$//' | sed 's/[[:space:]]*$//' | grep -v "^main$" | head -1)
        
        if [ -n "$tracked_branch" ]; then
            log_info "Checking out tracked branch: $tracked_branch"
            gt branch checkout "$tracked_branch" || log_warning "Failed to checkout tracked branch"
        else
            log_warning "No tracked branches found, skipping restack"
        fi
    fi
    
    # Now try restack if we're on a tracked branch
    if gt branch info > /dev/null 2>&1; then
        # Check if branches are behind main (likely to cause conflicts)
        local current_branch=$(get_current_branch)
        local main_sha=$(git rev-parse origin/main 2>/dev/null || git rev-parse main)
        local branch_sha=$(git rev-parse "$current_branch")
        
        # If branch is not based on main, restack might cause conflicts
        if ! git merge-base --is-ancestor "$main_sha" "$branch_sha" 2>/dev/null; then
            log_warning "Branch $current_branch appears to be behind main, restack may cause conflicts"
            log_info "Skipping restack to avoid conflicts. You can run 'gt stack restack' manually later if needed."
        else
            if gt stack restack; then
                log_success "Successfully restacked"
            else
                log_warning "Restack failed - this may be due to merge conflicts"
                log_info "You can resolve conflicts manually and run 'gt continue' to continue"
                log_info "Or run 'gt rebase --abort' to cancel the rebase"
                log_info "Continuing with sync operation..."
            fi
        fi
    else
        log_warning "Skipping restack - no tracked branch available"
    fi
    
    # Note: We don't call 'gt repo sync' here - let the user run it manually if needed
    # This avoids the verbose output from gt checking all local branches
    
    # Navigate back to appropriate branch
    navigate_back_to_original_or_bottom "$original_branch"
    
    log_success "Post-squash-merge cleanup completed successfully!"
}

# Main execution
main() {
    log_info "Post-Squash-Merge Cleanup Script"
    log_info "================================="
    
    # Pre-flight checks
    check_gt_command
    check_gh_command
    check_git_repo
    check_tracked_branch
    
    # Run main cleanup
    main_cleanup
}

# Run main function
main "$@"
