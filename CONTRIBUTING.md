# Contributing to QuranDaily

QuranDaily is maintained by a small team (often solo). **Still use pull requests** for changes—even when you are the only developer. That keeps `main` stable, leaves a clear history, and matches how GitHub records merged work.

## Workflow: branch → PR → merge

Do **not** push large changes directly to `main` unless it is an emergency hotfix.

1. **Update `main`**
   ```bash
   git checkout main
   git pull origin main
   ```

2. **Create a branch** (short, descriptive name)
   ```bash
   git checkout -b feat/now-playing-lock-screen
   # or: fix/continue-reading-empty-state, chore/app-store-checklist
   ```

3. **Commit** on the branch (small, focused commits when possible)
   ```bash
   git add <files>
   git commit -m "[scope] Imperative description"
   ```
   Examples: `[audio] Add lock screen Now Playing metadata`, `[reader] Fix Continue Reading on first launch`

4. **Push** and open a PR on GitHub
   ```bash
   git push -u origin feat/now-playing-lock-screen
   ```
   Then: **Compare & pull request** → target `main` → fill in summary and test plan.

5. **Merge** the PR on GitHub (squash or merge commit—either is fine). Delete the branch after merge.

6. **Sync locally**
   ```bash
   git checkout main
   git pull origin main
   ```

## Pull request template (minimal)

Use this in the PR description when it helps:

```markdown
## Summary
- What changed and why (1–3 bullets)

## Test plan
- [ ] Built and ran on simulator/device
- [ ] Relevant flow tested (Read / Listen / Settings / IAP)
```

## Commit messages

- Prefix with a scope in brackets: `[audio]`, `[reader]`, `[listen]`, `[settings]`, `[chore]`
- Use imperative mood: **Add**, **Fix**, **Update** (not “Added” / “Fixed”)
- No period at the end of the subject line

## Code conventions

- New Swift files: use the Xcode-style header (see `.cursor/rules/swift-file-header.mdc`)
- Match existing layout: `Domain/`, `Data/`, `Presentation/`, MVVM + `AppContainer`
- Do not commit secrets, `.env`, or local-only config

## Reviews

Solo PRs do not need a second human reviewer, but it is still worth skimming the **Files changed** tab before merging—same discipline as external contributors.

## Questions

Open a GitHub issue or discuss in the PR if something is unclear.
