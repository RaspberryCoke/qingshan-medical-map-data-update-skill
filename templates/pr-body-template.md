## Summary

This PR updates approved medical map JSON data based on manually reviewed
feedback.

## Related Issue

Closes #<issue-number>

## Changes

- Updated approved medical map JSON entries.
- Limited this PR to committed map data changes.
- Did not modify `shares`.

## Validation

- JSON parse passed.
- `git diff --check` passed.
- Draft PR is from `origin/codex/<task-slug>` to `upstream/main`.
- PR branch is rebased on latest `upstream/main`.
- Linear branch history checked.
- Full app test suite: <passed / not run locally; rely on PR checks>.

## Risk

Risk is limited to the approved JSON data changes. Medical resource information
can become stale, so cautious notes wording and manual review remain required.

## Merge

Please use Squash merge when this PR is ready.
