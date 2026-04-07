# MemPalace Claude Plugin

This package is the Claude-installable MemPalace runtime.

It provides:

- the MemPalace MCP server through `.mcp.json`
- `SessionStart`, `Stop`, and `PreCompact` hooks through `hooks/hooks.json`
- bootstrap scripts that create and reuse a Python runtime under `${CLAUDE_PLUGIN_DATA}`

## Install

From the repository root:

```bash
claude plugin marketplace add /absolute/path/to/mempalace
claude plugin install mempalace@mempalace-dev --scope local
```

## Config

The plugin prompts for:

- `palace_path`
- `startup_wing`
- `save_interval`

Defaults:

- `palace_path`: `~/.mempalace/palace`
- `startup_wing`: `claude`
- `save_interval`: `15`

## Doctor

Run:

```bash
bash plugins/claude/mempalace/scripts/plugin-doctor.sh
```

The doctor reports:

- the runtime Python path
- the resolved palace path
- whether the palace path exists yet
- whether packaged hooks are executable
- whether the packaged Python install imports `mempalace`
- whether the plugin log directory is writable

If `palace_path_exists=no`, the plugin is still installed. It just means the palace has not been created yet.

## Recovery

If the runtime gets stuck or corrupted:

```bash
rm -rf ~/.claude/plugins/data/mempalace*
claude plugin uninstall mempalace@mempalace-dev --scope local
claude plugin install mempalace@mempalace-dev --scope local
```

If the plugin is no longer needed:

```bash
claude plugin uninstall mempalace@mempalace-dev --scope local
```
