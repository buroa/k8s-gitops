# upstream-ahead  

Compare upstream/main to what you've already reviewed, showing only new commits since last review. Uses a tracking branch `upstream-reviewed` to remember what you've already seen.

## Task

1. Fetch latest changes from both upstream and origin remotes using `git fetch upstream && git fetch origin`
2. Check if `upstream-reviewed` tracking branch exists:
   - If it doesn't exist, create it pointing to origin/main: `git branch upstream-reviewed origin/main`
   - If it exists, use it as the baseline for comparison
3. Compare using `git log --format="%h %an %s" upstream-reviewed..upstream/main | grep -v "bot-blake"`
4. Display results showing new commits since last review
5. Only show commits by actual developers (filter out bot-blake renovate updates)
6. Present as a clean list with commit hash, author, and subject line
7. After showing results, ask user if they want to analyze specific commits for cherry-picking
8. If they provide commit hash(es), use `/cherry-pick <commit-hash>` to evaluate each one
9. **After user finishes reviewing**: Ask if they want to mark all shown commits as "reviewed"
10. If yes, advance the tracking branch: `git branch -f upstream-reviewed upstream/main`

This approach uses Git's native branching to track what you've already reviewed, eliminating the need for custom ignore files. The `upstream-reviewed` branch acts as a bookmark of your review progress.