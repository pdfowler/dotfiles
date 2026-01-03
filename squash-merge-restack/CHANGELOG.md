# GT Stack Sync Changelog

## 2025-10-14 - Targeted Bug Fixes

### Fixed Issues

#### 1. **Branch Name Parsing Bug** (The `dcfac6149` issue)
**Problem:** When finding local branches tracking remote branches, the script used `cut -d' ' -f2` which would sometimes return commit SHAs instead of branch names.

**Fix:** Replaced `cut` with `awk` for robust parsing:
```bash
# OLD (broken):
local_branch=$(git branch -vv | grep "origin/$remote_branch" | cut -d' ' -f2)

# NEW (fixed):
local_branch=$(git branch -vv | grep "\[origin/$remote_branch\]" | awk '{if ($1 == "*") print $2; else print $1}')
```

**Impact:** No more mysterious commit SHAs appearing as branch names.

---

#### 2. **No Fail-Fast Behavior** (Plowed ahead after conflicts)
**Problem:** When `process_merge_commit()` failed (returned error code), the script would just skip incrementing the counter and continue processing, leaving the repo in a broken state.

**Fix:** Added explicit fail-fast check:
```bash
if process_merge_commit "$commit_sha" "$commit_line"; then
    ((processed_count++))
else
    log_error "Failed to process merge commit $commit_sha"
    log_error "Stopping to prevent further issues."
    exit 1
fi
```

**Impact:** Script now stops immediately on conflicts instead of continuing and causing cascading failures.

---

#### 3. **Confusing Output** (63 merge commits with warnings)
**Problem:** Script would scan all merge commits on main and print a warning for each one not in the current stack, making it look like something was wrong.

**Fix:**
- Reduced verbosity in helper functions (removed unnecessary log_info/log_warning calls)
- Added summary message at start: "Found X merge commits, checking which are in current stack"
- Added summary at end: "Processed X commits (skipped Y not in current stack)"
- Changed individual skip messages to silent returns

**Impact:** Output is much cleaner and makes it clear that scanning many commits is normal behavior.

---

### What Wasn't Changed

- **Core algorithm:** The script still does the same thing - find merged branches, squash/rebase them, clean up
- **Merge commit scanning:** Still scans all merges on main (this is intentional and necessary)
- **Stack detection logic:** Still only processes branches that are in the current stack
- **Cleanup behavior:** Still removes branches identical to main

### Documentation Improvements

- Added detailed header comments explaining how the script works
- Clarified why scanning many merge commits is normal
- Documented the fail-fast behavior

---

## Why These Were Targeted Fixes

The original script was working well after significant effort. Rather than rewriting it entirely, these fixes address the specific reported issues:

1. Branch name parsing was causing actual failures
2. Lack of fail-fast was dangerous
3. Confusing output made the script seem broken when it wasn't

The core logic that handles squash-merge detection and rebase operations remains intact and battle-tested.



