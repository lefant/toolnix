## Summary

Aligned the tracked default reasoning depth for `pi` and `codex` so both agent paths now default to `gpt-5.4` with a high-effort reasoning setting.

## What changed

Updated:

- `agents/pi-coding-agent/templates/settings.json`

Result:

- `pi` now uses `"defaultThinkingLevel": "high"`
- `codex` already used `model_reasoning_effort = "high"`

## Why

The repo was already aligned on the same default model (`gpt-5.4`) but not on default reasoning depth:

- `pi`: `medium`
- `codex`: `high`

That created an avoidable behavioral mismatch between the tracked agent defaults. The new setting makes the default posture explicit and consistent for coding work.

## Notes

- this is a template/default change only
- existing user-local configs that were already created from these templates are not automatically overwritten by this repo change
