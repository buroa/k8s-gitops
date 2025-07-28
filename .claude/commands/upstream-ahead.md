# upstream-ahead

Compare origin/main to upstream/main and show commits where upstream is ahead of origin, excluding bot-blake (renovate) commits.

## Task

1. Fetch latest changes from both upstream and origin remotes using `git fetch upstream && git fetch origin`
2. Compare branches using `git log --format="%h %an %s" origin/main..upstream/main | grep -v "bot-blake"`
3. Display the results showing commits where upstream/main is ahead of origin/main
4. Only show commits by actual developers (filter out bot-blake renovate updates)
5. Present as a clean list with commit hash, author, and subject line
6. After showing the results, ask the user if they want to analyze any specific commits for cherry-picking
7. If they provide commit hash(es), use `/cherry-pick <commit-hash>` to evaluate each one

This helps identify meaningful upstream changes that can be cherry-picked or merged, while ignoring automated dependency updates. You can chain this with `/cherry-pick <hash>` to analyze specific commits.