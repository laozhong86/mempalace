# Codex Plugin Contract

## Required package entrypoint

The Codex plugin entrypoint lives at `.codex-plugin/plugin.json`. Codex treats that file as the required manifest for the plugin package, and the package root can also bundle `skills/`, `.mcp.json`, `.app.json`, and assets.

## Discovery location

Codex can discover plugins from a marketplace file at `$REPO_ROOT/.agents/plugins/marketplace.json` or `~/.agents/plugins/marketplace.json`. For local development, the marketplace entry can point directly at the repository checkout. Once installed, Codex caches the plugin under `~/.codex/plugins/cache/$MARKETPLACE_NAME/$PLUGIN_NAME/$VERSION/`.

## Supported manifest fields

The manifest fields we rely on are `name`, `version`, `description`, `author`, `homepage`, `repository`, `license`, `keywords`, `mcpServers`, and `interface`. The `interface` object can carry install-surface metadata such as `displayName`, `shortDescription`, `longDescription`, `developerName`, `category`, `defaultPrompt`, `brandColor`, `logo`, `composerIcon`, and `screenshots`.

## Unsupported assumptions removed

The plugin does not assume `.claude-plugin/` is the Codex surface. It does not assume Codex will provide `CLAUDE_PLUGIN_ROOT` or `CLAUDE_PLUGIN_DATA`. It does not assume hooks are part of the Codex plugin package, and it does not assume runtime config should be hard-coded to a user-specific absolute path.
