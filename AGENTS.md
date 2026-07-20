# Repository Guidelines

## Git workflow

- Treat `main` as protected. Do not commit or push changes directly to `main`.
- Before starting work, confirm the working tree is understood and update local `main` with a fast-forward pull.
- Make changes on the long-lived `feature` branch, which should start from the latest `main`.
- Stage only files that belong to the requested change, run the relevant checks, and push `feature` to GitHub.
- Open or update a draft pull request from `feature` into `main`.
- Do not merge the pull request until the user explicitly asks to merge it. Approval to create or push a feature branch is not approval to merge.
- After an approved merge, update local `main`, fast-forward `feature` to the merged `main`, and push the synchronized branch. Keep the long-lived `feature` branch.

## Commit attribution

- When Codex materially authors a change, use the verified GitHub identity `Codex <chatgpt-codex-connector[bot]@users.noreply.github.com>`.
- Do not rewrite existing history solely to change attribution.
