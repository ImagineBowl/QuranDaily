# GitHub workflow (solo + Pull Shark)

QuranDaily uses `main` as the default branch. Even when you work alone, opening **pull requests** and **merging on GitHub** counts toward profile achievements (e.g. Pull Shark) and keeps a clear history.

## Quick flow

```bash
# 1. Start from latest main
git checkout main
git pull origin main

# 2. Create a feature branch (pick a clear name)
git checkout -b feat/now-playing-polish
# or: fix/continue-reading-empty-state

# 3. Work and commit (one topic per commit when you can)
git add <files>
git commit -m "[audio] Improve mini player expand target"

# 4. Push branch
git push -u origin HEAD

# 5. Open PR on GitHub
gh pr create --title "[audio] Improve mini player expand target" --body "$(cat <<'EOF'
## Summary
- Tap progress bar and title area to expand Now Playing

## Test plan
- [ ] Play audio from Listen tab
- [ ] Tap mini player bar (not only play button)
EOF
)"

# 6. Merge (squash or merge commit — your preference)
gh pr merge --squash
# or review in browser and click Merge

# 7. Sync local main
git checkout main
git pull origin main
```

## Branch naming

| Prefix | Use for |
|--------|---------|
| `feat/` | New feature or UX improvement |
| `fix/` | Bug fix |
| `chore/` | Tooling, headers, docs, no user-facing change |

Optional ticket prefix: `feat/APP-123-short-description`

## Commit messages

Match existing style:

```
[scope] Imperative description
```

Examples: `[reader] Hide Continue Reading until position is saved`, `[listen] Reset ayah when surah changes`

- Scope: `reader`, `listen`, `audio`, `settings`, `chore`, etc.
- No period at the end
- Author: you only (avoid unrelated co-author trailers)

## When to skip a PR

Fine to push directly to `main` for tiny hotfixes if you prefer — you just won’t get PR-based achievement credit for that change. For anything you might want in release notes, use a PR.

## Achievements (GitHub profile)

| Badge | How it usually unlocks |
|-------|-------------------------|
| **Pull Shark** | Merged pull requests (tiered by count) |
| **Quickdraw** | Close issue/PR very soon after opening |
| **Pair Extraordinaire** | Co-authored commits on merged PRs |
| **Starstruck** | High stars on a repo you own |
| **Galaxy Brain** | Accepted answer on discussions |

Show achievements: GitHub profile → ensure “Show achievements” is enabled in profile settings.

## Protected `main` (optional later)

If you add branch protection:

- Require PR before merge
- No force-push to `main`

Until then, discipline is: branch → PR → merge → delete branch.

## Related

- App Store submission: see team checklist (create `docs/APP_STORE_CHECKLIST.md` when ready)
- Remote: `origin` → `https://github.com/ImagineBowl/QuranDaily.git`
