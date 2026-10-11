# CLAUDE.md

## Coding style: always use ponytail

For every coding task in this repo (writing, fixing, refactoring, reviewing), invoke the `ponytail:ponytail` skill first and follow it.

- Make the smallest change that fully solves the task. Use as little code as possible.
- No speculative features, abstractions, config options or dependencies (YAGNI).
- Reuse what already exists before writing anything new.
- Prefer deleting code to adding it.
- Keep replies short and easy to understand on one read.
- Use `ponytail:ponytail-review` to review changes and `ponytail:ponytail-audit` for whole-repo cleanups.

## Pushing: always sync with GitHub first

Before every push, run `git fetch origin` and check for new commits on the remote branch. If there are any, merge them into the local changes first, then push. Never force-push over remote changes.

`index.html` keeps the whole app template on one line, so git can't merge two edits to it. To merge, decode the template from both versions, line-diff them, apply our changes on top of the remote version, re-encode, and check that both sides' changes are present before pushing.
