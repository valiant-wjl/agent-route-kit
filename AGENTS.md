# Agent Instructions

This repository is intended to be deployed by an AI agent after a human fills `agent-input.env`.

## Operating Rules

- Do not commit `agent-input.env`, `build/`, generated QR codes, logs, private keys, or generated configs with secrets.
- Do not ask the human to edit templates. Ask only for missing keys from `agent-input.example.env`.
- Treat `docs/AGENT_DEPLOYMENT.md` as the deployment runbook.
- Use `agent-manifest.json` as the machine-readable contract.
- Run `make smoke` after edits and before publishing.
- Prefer `tools/net` and `tools/diagnose` over ad hoc commands for local operations.
- The dashboard is a convenience UI; CLI commands remain the automation source of truth.

## Deployment Flow

1. Copy `agent-input.example.env` to `agent-input.env`.
2. Ask the human to fill private values.
3. Run `bash scripts/check-prereqs.sh agent-input.env`.
4. Run `python3 tools/render-config.py --env agent-input.env --out build`.
5. Run `bash scripts/install-local-macos.sh build`.
6. Run `bash scripts/deploy-relay.sh build`.
7. Run `bash tools/net on`.
8. Run `bash tools/diagnose`.
9. Run `make smoke`.

Stop only for missing human-provided inputs, unreachable relay access, or environment prerequisites that cannot be installed automatically.
