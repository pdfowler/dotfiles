## gt stack sync
The logic is supposed to: 
1- start at the current branch,
2- use GT branch bottom command to go to the bottom of the stack (ie: "BASE")
3- identify the branch point off of main
4- walk up each commit on Main to identify the corresponding PR
5- for each PR, determine its source branch 
6- if the source branch of a merged PR matches the BASE branch of the stack: squash the BASE branch into a single commit.|
7- then, go up the stack (gt branch up), note that branch as BASE, return to the new stack branch point off of main and continue walking up (repeating steps 4-6)
8- once you find HEAD on main; run `gt stack restack`
9- for each branch in the stack that has the same SHA as MAIN:HEAD - delete the branch (`gt branch delete {branchName}` iirc)

Message:
>>>
➜  ENG-5855_endpoints git:(inspections-revamp-store-page) gt stack sync
[INFO] Post-Squash-Merge Cleanup Script
[INFO] =================================
[SUCCESS] gt command found
[SUCCESS] gh command found
[SUCCESS] Git repository detected
[SUCCESS] Current branch is tracked by Charcoal
[INFO] Starting post-squash-merge cleanup...
[INFO] Starting from branch: inspections-revamp-store-page
[INFO] Fetching latest changes from origin/main...
From github.com:shiftsmartinc/monorepo
 * branch                main       -> FETCH_HEAD
[SUCCESS] Successfully fetched latest changes from origin/main
[INFO] No merge commits to process.
[INFO] Checking for branches identical to main or empty...
[INFO] Found branches to check: feat/ENG-5786/load_territories_for_breadcrumbs
feat/ENG-5786/get_territory_endpoint
inspections-revamp-store-page
feat/support-git-worktrees
[INFO] Checking branch: 'feat/ENG-5786/load_territories_for_breadcrumbs'
[INFO] Branch feat/ENG-5786/load_territories_for_breadcrumbs is not identical to main and not empty, keeping
[INFO] Checking branch: 'feat/ENG-5786/get_territory_endpoint'
[INFO] Branch feat/ENG-5786/get_territory_endpoint is not identical to main and not empty, keeping
[INFO] Checking branch: 'inspections-revamp-store-page'
[INFO] Branch inspections-revamp-store-page is not identical to main and not empty, keeping
[INFO] Checking branch: 'feat/support-git-worktrees'
[INFO] Branch feat/support-git-worktrees is not identical to main and not empty, keeping
[INFO] No identical or empty branches found
[INFO] Performing final restack...
[WARNING] Branch inspections-revamp-store-page appears to be behind main, restack may cause conflicts
[INFO] Skipping restack to avoid conflicts. You can run 'gt stack restack' manually later if needed.
[INFO] Syncing with main...
🌲 Pulling main from remote...
main is up to date.
no pull requests found for branch "main"
no pull requests found for branch "backup/feat/ENG-5786/revamp-territories-page-11-23-52\u202fPM"
no pull requests found for branch "backup/ENG-5888/inspections-clean-up-routes-11-46-16\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5888_route_cleanup-11-05-39\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5888_route_cleanup-11-03-45\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5888_route_cleanup-11-04-24\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5888_route_cleanup"
no pull requests found for branch "chore/align_auth0_configs"
no pull requests found for branch "backup/inspections-territories-revamp-BE-10-08-07\u202fAM"
no pull requests found for branch "feat/ENG-5786/cleanup-routes-reconciliation"
no pull requests found for branch "backup/origin/ENG-5888/inspections-clean-up-routes"
no pull requests found for branch "ENG-5888/inspections-clean-up-routes-v2"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5896_web_territory_filtering-9-05-31\u202fAM"
no pull requests found for branch "integration/ENG-5896_stack"
no pull requests found for branch "feat/ENG-5786/ENG-5896_territory_filtering/web"
no pull requests found for branch "feat/ENG-5786/ENG-5896_territory_filtering/api-was-here"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5896_territory_filtering/web-3-18-25\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5896_territory_filtering/web-2-50-26\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5896_territory_filtering/api-3-15-17\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5896_territory_filtering/web-2-36-48\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5896_territory_filtering/web-2-38-33\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5896_web_territory_filtering-2-17-13\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5896_web_territory_filtering-2-22-35\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/ENG-5896_api_territory_filtering-2-11-08\u202fPM"
no pull requests found for branch "feat/ENG-5786/2025-10-02_demo"
no pull requests found for branch "backup/feat/ENG-5786/2025-10-02_demo_web-2-33-17\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/2025-10-02_demo_web-2-34-42\u202fPM"
no pull requests found for branch "test/a"
no pull requests found for branch "track"
no pull requests found for branch "backup/feat/ENG-5786/2025-10-02_demo_web-3-13-14\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/2025-10-02_demo_api-3-12-34\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/2025-10-02_demo-3-13-45\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/2025-10-02_demo_api-3-00-12\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/2025-10-02_demo_web-2-58-43\u202fPM"
no pull requests found for branch "backup/feat/ENG-5786/2025-10-02_demo_web-3-04-45\u202fPM"
no pull requests found for branch "feat/ENG-5786/separate-api-and-web-commits-into-branches-dc2e"
no pull requests found for branch "001-update-terrraform-configs-from-current-runtime"
no pull requests found for branch "feat/ENG-5786/territory-list-page-rebased"
no pull requests found for branch "backup/feat/ENG-5786/inspections-data-fetch-FE-2-57-30\u202fPM"
no pull requests found for branch "feat/ENG-5786/add-search-functionality"
no pull requests found for branch "backup/feat/ENG-5786/territory-list-page-6-05-13\u202fPM"
no pull requests found for branch "feat/ENG-5786/territory-list-page"
no pull requests found for branch "feat/ENG-5786/ui-connections-and-queries"
no pull requests found for branch "backup/feat/ENG-5786/ui-connections-and-queries-12-18-02\u202fAM"
no pull requests found for branch "backup/feat/ENG-5786/territory-list-page-12-20-03\u202fAM"
no pull requests found for branch "backup/feat/ENG-5786/add-search-functionality-12-24-09\u202fAM"
no pull requests found for branch "feat/ENG-5786/ENG-5790_store_details_api"
no pull requests found for branch "feat/ENG-5786/ENG-5790_store_details_api-restacked"
no pull requests found for branch "tmp/branch"
no pull requests found for branch "build/ENG-5786/2025-09-26-demo"
no pull requests found for branch "test/2025-09-26-demo"
no pull requests found for branch "dx/eslint-config-inheritance"
no pull requests found for branch "dx/apollo-remote-types-fallback"
no pull requests found for branch "fix/rbac_permission_naming"
no pull requests found for branch "build/auth-debugging"
no pull requests found for branch "dx/seed-from-prod/ac-bifurcation"
no pull requests found for branch "AC-remove-scheduled-jobs"
no pull requests found for branch "fix/BUG-3599_investigation"
no pull requests found for branch "feat/ENG-5492_schedule_publish_start_end"
no pull requests found for branch "feat/ENG-5383_squashed"
no pull requests found for branch "test/b"
no pull requests found for branch "test/c"
🧹 Checking if any branches have been merged/closed and can be deleted...
[SUCCESS] Successfully synced with main
[INFO] Navigating back to appropriate branch...
Already on inspections-revamp-store-page.
[SUCCESS] Returned to original branch: inspections-revamp-store-page
[SUCCESS] Post-squash-merge cleanup completed successfully!
➜  ENG-5855_endpoints git:(inspections-revamp-store-page) pwd
/Users/pdfowler/Development/shiftsmart/services/ENG-5855_endpoints
```
<<<