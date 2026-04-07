# MemPalace Claude Plugin Spec

Last updated: 2026-04-07

## Goal

Turn the current MemPalace Claude Code plugin into a first-class plugin product:

- installs through Claude Code's official plugin flow
- does not require users to hand-edit `~/.claude.json` or `settings.local.json`
- is self-contained inside the plugin cache
- is safe to roll out to teams through a marketplace
- exposes a clear setup path for palace path, startup wing, and save behavior

This spec is about the Claude Code plugin surface, not the broader MemPalace CLI or MCP design.

## Why Claude plugins matter

Claude Code plugins have three concrete product advantages over ad-hoc setup.

First, installation becomes standard. Users add a marketplace and run `claude plugin install`. They do not need to manually register MCP servers or copy hook snippets into multiple config files.

Second, distribution becomes team-friendly. Claude Code supports marketplace catalogs, project-level recommended marketplaces, default-enabled plugins, and pre-populated plugin seeds for containers and CI. That makes MemPalace deployable across a team instead of staying a local power-user setup.

Third, lifecycle management becomes predictable. Plugin versions are tracked, updates are explicit, and the runtime sits behind Claude Code's own plugin cache and enable/disable model.

Official references:

- Plugins reference: https://code.claude.com/docs/en/plugins-reference
- Plugin marketplaces: https://code.claude.com/docs/en/plugin-marketplaces

## Claude plugin best practices

Based on the official docs and current behavior, these are the plugin rules that matter most for MemPalace.

### 1. Use the standard plugin layout

Claude already auto-discovers `hooks/hooks.json` and `.mcp.json` in the plugin root. Do not redundantly declare those in `plugin.json` unless you are pointing at additional non-standard files.

### 2. Keep the plugin self-contained

Marketplace plugins are copied into Claude's local plugin cache. Anything outside the plugin root is not available after install. The plugin must not depend on sibling paths, repo-relative traversal, or user-specific absolute paths.

### 3. Keep the plugin payload lean

The cache should not include repo-local `.venv`, test fixtures, benchmarks, or unrelated development files if they are not required at runtime. A plugin source that points at the whole repository is acceptable for local development, but not ideal for public distribution.

### 4. Prefer user-configurable fields over manual edits

Claude plugins support `userConfig`. If users need to set `palace_path`, `startup_wing`, or `save_interval`, the plugin should ask for those values at enable/install time instead of requiring them to edit JSON by hand.

### 5. Use project settings for team adoption

If a repo wants MemPalace by default, the project should declare `extraKnownMarketplaces` and `enabledPlugins` in `.claude/settings.json`. That lets Claude prompt collaborators to install the marketplace when they trust the repo.

### 6. Treat bootstrap as production code

If the plugin needs a runtime bootstrap, it must be:

- idempotent
- fast on the common path
- robust across updates
- explicit about logs and failure modes
- isolated to Claude's plugin data directory

### 7. Fail clearly and degrade safely

If bootstrap fails, users should get a precise error in the plugin log or MCP startup log. Hooks should avoid corrupting the session. The plugin should not silently half-work.

## Current state

The current MemPalace plugin already proves the core concept.

What works now:

- valid `plugin.json`
- valid `marketplace.json`
- valid local marketplace install flow
- standard plugin enablement in project local scope
- plugin-provided `.mcp.json`
- plugin-provided `SessionStart`, `Stop`, and `PreCompact` hooks
- SessionStart injection verified in Claude
- MCP access verified in Claude under plugin-managed load

Relevant files:

- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `.mcp.json`
- `hooks/hooks.json`
- `scripts/plugin-*.sh`

## Current weaknesses

The current implementation is functional, but not release-grade.

### 1. Plugin source is too large

The marketplace entry points at the repository root (`source: "./"`). That means Claude caches the entire repo, including development-only content. This increases install/update size and makes runtime behavior harder to reason about.

### 2. Runtime bootstrap is too heavy

The plugin bootstraps by creating a Python virtualenv and running `pip install -e <plugin-root>`. That works for local iteration, but it is not a good default for a public plugin:

- editable install is a development pattern, not a distribution pattern
- it pulls in build tooling on first launch
- it increases first-run latency
- it can fail on update or partial cleanup

### 3. Bootstrap cleanup is brittle

We observed a real failure during plugin bootstrap when deleting the previous venv. The current `rm -rf` path can fail and leave the runtime in a confusing partial state.

### 4. Configuration surface is still implicit

The plugin runtime currently depends on environment variables such as:

- `MEMPALACE_PALACE_PATH`
- `MEMPALACE_SAVE_INTERVAL`
- `MEMPALACE_STARTUP_WING`

There is no plugin-native `userConfig` yet, so install-time configuration is still weak.

### 5. Data directory handling is inconsistent

The plugin originally assumed a fallback directory under `~/.claude/plugins-data/...`, while Claude's actual plugin data path is under `~/.claude/plugins/data/...`. The plugin should trust `CLAUDE_PLUGIN_DATA` first and avoid inventing alternate conventions.

### 6. No team rollout story in repo config yet

The plugin can be installed manually, but the repository does not yet declare a recommended marketplace or default-enabled plugin in `.claude/settings.json`.

### 7. No plugin-specific doctor command

If the plugin fails to start, users currently have to infer the cause from Claude behavior or plugin logs. There is no dedicated health-check command for:

- runtime present
- MCP server starts
- palace path exists
- hooks are executable
- plugin config values resolved as expected

## Product direction

MemPalace should be positioned as a Claude-native memory plugin, not just "the old MCP server plus some shell scripts".

The plugin's product promise should be:

"Install once, choose a palace, and Claude gets persistent memory with search, wake-up context, and save checkpoints."

That implies three product layers:

1. Runtime layer
   The MCP server and hooks start reliably with no hand configuration.

2. Setup layer
   The user chooses palace path and behavior through plugin config, not shell edits.

3. Distribution layer
   Teams can publish, install, update, and seed the plugin through normal Claude Code mechanisms.

## Proposed target architecture

### Plugin packaging

Create a dedicated plugin distribution directory, for example:

`plugins/claude/mempalace/`

That directory should contain only runtime-required assets:

- `.claude-plugin/plugin.json`
- `.mcp.json`
- `hooks/hooks.json`
- `scripts/`
- minimal `mempalace/` Python package or an installable wheel asset
- runtime README
- optional commands/skills if needed

The marketplace entry should point at that plugin directory, not repo root.

### Runtime

Move from editable install toward one of these two models:

#### Preferred: bundled wheel install

Build a wheel for the plugin runtime and install that wheel into the plugin data venv.

Why:

- deterministic
- smaller dependency surface than editable mode
- clearer version semantics
- avoids relying on build-editable support inside the cached plugin source

#### Acceptable fallback: non-editable local install

If wheel bundling is deferred, use `pip install <plugin-root>` instead of `pip install -e <plugin-root>`.

### Plugin configuration

Add `userConfig` to `plugin.json` for at least:

- `palace_path`
- `startup_wing`
- `save_interval`

Optional later:

- `state_dir`
- `enable_diary_hooks`
- `default_project_wing`

The runtime wrappers should map those values into environment variables consumed by hooks and the MCP server.

### Project onboarding

For repos that want MemPalace as standard workflow, add `.claude/settings.json` like:

- `extraKnownMarketplaces`
- `enabledPlugins`

That gives new collaborators an official prompt-driven install path.

### Diagnostics

Add a plugin command such as `/mempalace-doctor` or `/mempalace-status` that checks:

- plugin version
- bootstrap status
- runtime Python path
- configured palace path
- collection count
- hook state/log path
- MCP server readiness

This should be the first troubleshooting surface.

## Recommended phased plan

### Phase 1: Hardening

Goal: make the current plugin reliable.

Work:

- stop using repo root as plugin source for anything beyond local development
- fix bootstrap cleanup to be atomic and resilient
- standardize on `CLAUDE_PLUGIN_DATA`
- remove all fallback assumptions that fight Claude's own plugin data model
- add plugin log messages for bootstrap start, reuse, upgrade, and failure

Acceptance:

- fresh install works
- update works
- reinstall works
- enable/disable works
- `claude -p` with plugin-managed MCP succeeds without debug flags

### Phase 2: User-configured install

Goal: remove hand configuration from the user journey.

Work:

- add `userConfig` to plugin manifest
- wire `palace_path`, `startup_wing`, `save_interval`
- document defaults and migration from old manual setup

Acceptance:

- a new user can install the plugin and configure it without editing JSON files
- plugin settings survive updates

### Phase 3: Team distribution

Goal: make MemPalace easy to adopt across a repo or org.

Work:

- publish the marketplace in a stable GitHub repo
- document project-level `.claude/settings.json` integration
- add seed-directory guidance for containers and CI

Acceptance:

- a team repo can recommend or auto-enable the plugin
- a container image can ship with the plugin pre-seeded

### Phase 4: Plugin-native UX

Goal: make the plugin feel like a Claude-native product.

Work:

- add doctor/status command
- add import/setup command for common transcript sources
- optionally add a guided "connect palace / import history" flow

Acceptance:

- setup, verification, and repair all happen through Claude-native plugin surfaces

## Concrete improvements to apply next

These are the next changes worth doing in order.

1. Create a dedicated plugin distribution directory and repoint marketplace `source`.
2. Replace editable install with wheel install or non-editable install.
3. Add `userConfig` for palace path, startup wing, and save interval.
4. Add atomic bootstrap semantics:
   build to a temp venv, then rename into place.
5. Add plugin log and doctor command.
6. Add project-level `.claude/settings.json` example for recommended install.
7. Trim runtime payload so the cached plugin is small and predictable.

## Acceptance criteria for "release-grade"

MemPalace should only be considered a real Claude plugin release when all of these are true:

- plugin installs through marketplace flow with no manual config edits
- plugin starts MCP successfully on a fresh machine
- SessionStart/Stop/PreCompact hooks all work under plugin install
- plugin config is handled through `userConfig`
- plugin update does not require deleting stale runtime state by hand
- plugin logs clearly explain failures
- repo-level enablement for teams is documented
- plugin cache does not include unrelated development artifacts

## Non-goals

This spec does not require:

- changing the MemPalace memory model
- replacing ChromaDB
- redesigning the MCP tool surface
- making the plugin work for non-Claude clients first

The near-term goal is a strong Claude Code plugin, not a universal extension system.
