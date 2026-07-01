# Local Dashboard

Zero-dependency local dashboard for AgentRouteKit.

It is intentionally small:

- Binds to `127.0.0.1` only.
- Calls only whitelisted local commands.
- Does not store or display secrets.
- Uses the same command contracts as automation agents.

## Run

```bash
python3 dashboard/server.py
```

Then open:

```text
http://127.0.0.1:8765
```

## Actions

- Status: `tools/net status`
- Diagnose: `tools/diagnose`
- On: `tools/net on`
- AI Only: `tools/net ai-only`
- Bypass: `tools/net bypass`

The dashboard is an operations convenience layer. The CLI remains the source of truth for automation.
