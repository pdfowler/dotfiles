#!/bin/bash

# cleanup-merged-branches.sh
# Utility script to clean up local git branches that have had their PRs merged
# and remote branches deleted (common with squash-merge workflows)

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
LIST_ONLY=false
DRY_RUN=false
VERBOSE=false
INCLUDE_CLOSED=false

# Function to show usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Clean up local git branches that have had their PRs merged and remote branches deleted."
    echo ""
    echo "OPTIONS:"
    echo "  --list, -l     List branches that would be deleted (dry run)"
    echo "  --dry-run, -d  Show what would be deleted without actually deleting"
    echo "  --verbose, -v  Show detailed output"
    echo "  --closed, -c   Include branches with closed (unmerged) PRs"
    echo "  --help, -h     Show this help message"
    echo ""
    echo "EXAMPLES:"
    echo "  $0 --list                    # Preview what would be deleted"
    echo "  $0 --dry-run                 # Show detailed deletion plan"
    echo "  $0                           # Actually delete merged branches"
    echo "  $0 --verbose                 # Delete with detailed output"
    echo "  $0 --closed                  # Include closed (unmerged) PRs"
    echo "  $0 --list --closed           # Preview including closed PRs"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --list|-l)
            LIST_ONLY=true
            shift
            ;;
        --dry-run|-d)
            DRY_RUN=true
            shift
            ;;
        --verbose|-v)
            VERBOSE=true
            shift
            ;;
        --closed|-c)
            INCLUDE_CLOSED=true
            shift
            ;;
        --help|-h)
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}❌ Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Check if gh CLI is available
if ! command -v gh >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: GitHub CLI (gh) is required but not found${NC}"
    echo -e "${YELLOW}💡 Install it with: brew install gh${NC}"
    exit 1
fi

# Check if gh is authenticated
if ! gh auth status >/dev/null 2>&1; then
    echo -e "${RED}❌ Error: GitHub CLI not authenticated${NC}"
    echo -e "${YELLOW}💡 Run: gh auth login${NC}"
    exit 1
fi

# Get the current branch
CURRENT_BRANCH=$(git branch --show-current)

# Get all local branches except main/master
LOCAL_BRANCHES=$(git branch --format='%(refname:short)' | grep -v -E '^(main|master)$')

if [[ -z "$LOCAL_BRANCHES" ]]; then
    echo -e "${GREEN}✓ No local branches to check (excluding main/master)${NC}"
    exit 0
fi

# Arrays to track branches
MERGED_BRANCHES=()
CLOSED_BRANCHES=()
NOT_MERGED_BRANCHES=()
ERROR_BRANCHES=()

if [[ "$INCLUDE_CLOSED" == "true" ]]; then
    echo -e "${BLUE}🔍 Checking local branches for merged and closed PRs...${NC}"
else
    echo -e "${BLUE}🔍 Checking local branches for merged PRs...${NC}"
fi
if [[ "$VERBOSE" == "true" ]]; then
    echo -e "${YELLOW}Current branch: $CURRENT_BRANCH${NC}"
    echo -e "${YELLOW}Branches to check: $(echo "$LOCAL_BRANCHES" | tr '\n' ' ')${NC}"
    echo ""
fi

# Check each branch
for branch in $LOCAL_BRANCHES; do
    if [[ "$VERBOSE" == "true" ]]; then
        echo -n "Checking branch '$branch'... "
    fi
    
    # Check if branch has a merged PR
    if gh pr list --head "$branch" --state merged --json number --jq '.[].number' >/dev/null 2>&1; then
        MERGED_BRANCHES+=("$branch")
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "${GREEN}✓ merged${NC}"
        fi
    elif [[ "$INCLUDE_CLOSED" == "true" ]] && gh pr list --head "$branch" --state closed --json number --jq '.[].number' >/dev/null 2>&1; then
        # Check if branch has a closed (unmerged) PR
        CLOSED_BRANCHES+=("$branch")
        if [[ "$VERBOSE" == "true" ]]; then
            echo -e "${YELLOW}⚠️  closed${NC}"
        fi
    else
        # Check if branch has any PR at all (to distinguish between no PR and not merged/closed)
        if gh pr list --head "$branch" --json number --jq '.[].number' >/dev/null 2>&1; then
            NOT_MERGED_BRANCHES+=("$branch")
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "${YELLOW}⚠️  has PR but not merged${NC}"
            fi
        else
            NOT_MERGED_BRANCHES+=("$branch")
            if [[ "$VERBOSE" == "true" ]]; then
                echo -e "${YELLOW}⚠️  no PR found${NC}"
            fi
        fi
    fi
done

# Summary
echo ""
echo -e "${BLUE}📊 Summary:${NC}"
if [[ "$INCLUDE_CLOSED" == "true" ]]; then
    echo -e "  ${GREEN}Merged branches (will be deleted): ${#MERGED_BRANCHES[@]}${NC}"
    echo -e "  ${YELLOW}Closed branches (will be deleted): ${#CLOSED_BRANCHES[@]}${NC}"
    echo -e "  ${BLUE}Branches to keep: ${#NOT_MERGED_BRANCHES[@]}${NC}"
else
    echo -e "  ${GREEN}Merged branches (will be deleted): ${#MERGED_BRANCHES[@]}${NC}"
    echo -e "  ${YELLOW}Branches to keep: ${#NOT_MERGED_BRANCHES[@]}${NC}"
fi

if [[ ${#MERGED_BRANCHES[@]} -eq 0 && ${#CLOSED_BRANCHES[@]} -eq 0 ]]; then
    if [[ "$INCLUDE_CLOSED" == "true" ]]; then
        echo -e "${GREEN}✓ No merged or closed branches found to delete${NC}"
    else
        echo -e "${GREEN}✓ No merged branches found to delete${NC}"
    fi
    exit 0
fi

# Show branches that will be deleted
echo ""
if [[ ${#MERGED_BRANCHES[@]} -gt 0 ]]; then
    echo -e "${BLUE}🗑️  Branches with merged PRs:${NC}"
    for branch in "${MERGED_BRANCHES[@]}"; do
        if [[ "$branch" == "$CURRENT_BRANCH" ]]; then
            echo -e "  ${RED}⚠️  $branch (CURRENT BRANCH - will be skipped)${NC}"
        else
            echo -e "  ${RED}❌ $branch${NC}"
        fi
    done
fi

if [[ "$INCLUDE_CLOSED" == "true" && ${#CLOSED_BRANCHES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BLUE}🗑️  Branches with closed PRs:${NC}"
    for branch in "${CLOSED_BRANCHES[@]}"; do
        if [[ "$branch" == "$CURRENT_BRANCH" ]]; then
            echo -e "  ${RED}⚠️  $branch (CURRENT BRANCH - will be skipped)${NC}"
        else
            echo -e "  ${RED}❌ $branch${NC}"
        fi
    done
fi

# Show branches that will be kept
if [[ ${#NOT_MERGED_BRANCHES[@]} -gt 0 ]]; then
    echo ""
    echo -e "${BLUE}🔒 Branches to keep:${NC}"
    for branch in "${NOT_MERGED_BRANCHES[@]}"; do
        echo -e "  ${GREEN}✓ $branch${NC}"
    done
fi

# Handle list-only mode
if [[ "$LIST_ONLY" == "true" || "$DRY_RUN" == "true" ]]; then
    echo ""
    echo -e "${YELLOW}💡 This was a preview. Run without --list or --dry-run to actually delete branches.${NC}"
    exit 0
fi

# Confirm deletion
echo ""
if [[ ${#MERGED_BRANCHES[@]} -gt 0 || ${#CLOSED_BRANCHES[@]} -gt 0 ]]; then
    # Filter out current branch from deletion
    BRANCHES_TO_DELETE=()
    for branch in "${MERGED_BRANCHES[@]}"; do
        if [[ "$branch" != "$CURRENT_BRANCH" ]]; then
            BRANCHES_TO_DELETE+=("$branch")
        fi
    done
    
    if [[ "$INCLUDE_CLOSED" == "true" ]]; then
        for branch in "${CLOSED_BRANCHES[@]}"; do
            if [[ "$branch" != "$CURRENT_BRANCH" ]]; then
                BRANCHES_TO_DELETE+=("$branch")
            fi
        done
    fi
    
    if [[ ${#BRANCHES_TO_DELETE[@]} -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  All branches are either the current branch or already processed${NC}"
        exit 0
    fi
    
    echo -e "${YELLOW}⚠️  About to delete ${#BRANCHES_TO_DELETE[@]} branch(es):${NC}"
    for branch in "${BRANCHES_TO_DELETE[@]}"; do
        echo -e "  ${RED}❌ $branch${NC}"
    done
    
    echo ""
    read -p "Are you sure you want to delete these branches? (y/N): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}Deletion cancelled${NC}"
        exit 0
    fi
    
    # Delete branches
    echo ""
    echo -e "${BLUE}🗑️  Deleting merged branches...${NC}"
    DELETED_COUNT=0
    
    for branch in "${BRANCHES_TO_DELETE[@]}"; do
        if git branch -D "$branch" >/dev/null 2>&1; then
            echo -e "  ${GREEN}✓ Deleted: $branch${NC}"
            ((DELETED_COUNT++))
        else
            echo -e "  ${RED}❌ Failed to delete: $branch${NC}"
        fi
    done
    
    echo ""
    echo -e "${GREEN}✅ Cleanup complete! Deleted $DELETED_COUNT branch(es)${NC}"
else
    echo -e "${GREEN}✓ No branches to delete${NC}"
fi
