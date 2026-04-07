# Codex Extension Guidelines for MemPalace

This document captures the development规范 and best practices for Codex-related extension work in this repository. It is meant to stay small, factual, and easy to update.

## What surface to use

Use the smallest surface that fits the job.

- Use a **skill** when the guidance is for local authoring, repo workflows, or a focused reusable procedure.
- Use a **plugin** when you want a distributable bundle that can be installed and discovered as a unit.
- Use **MCP** when the goal is to connect Codex to a tool or service.
- Use **hooks** when the work is deterministic lifecycle automation, such as save checkpoints or pre-compaction actions.

Do not mix those concerns in one file. Keep each surface as its own truth source.

## Repository rule: keep the map short

OpenAI’s Codex guidance is consistent on one point: `AGENTS.md` should act like a map, not a manual. The deeper knowledge should live in structured docs, with short pointer files in the repo root or relevant subdirectories.

For MemPalace, that means:

- Keep top-level instructions concise.
- Put durable implementation guidance in `docs/`.
- Keep hook-specific behavior in `hooks/README.md` and the hook scripts themselves.
- Keep machine-local behavior out of shared guidance unless it is truly general.

## Plugin packaging rules

If this repository later grows a Codex plugin package, use the plugin manifest as the source of truth.

- Keep the plugin manifest in `.codex-plugin/plugin.json`.
- Treat the marketplace metadata as a separate file and validate it independently.
- Keep plugin packaging separate from runtime hook activation.
- Only include `.mcp.json` in the plugin package when MCP metadata is part of the distributable package.
- Prefer explicit, minimal metadata over clever indirection.

Practical rule: if a change only affects installability or discovery, it belongs in the plugin package. If it affects runtime behavior after installation, it probably belongs somewhere else.

## Hook design rules

The existing MemPalace hook scripts already point to the right model.

- Keep hooks local and deterministic.
- Avoid network calls in hooks unless the hook is explicitly for a remote integration.
- Make hook state explicit and durable. The current scripts store state under `~/.mempalace/hook_state`.
- Keep trigger logic separate from ingestion logic.
- Protect against loops when a hook causes the agent to continue working and then stop again.
- Prefer `Stop` for periodic save checkpoints.
- Prefer `PreCompact` for mandatory pre-compaction saves.

The current implementation in `hooks/mempal_save_hook.sh` and `hooks/mempal_precompact_hook.sh` is a good reference: it uses local state, logs to a file, and avoids trying to infer meaning from the transcript with brittle rules.

## Prompting and repository context

Codex performs better when prompts look like a good GitHub issue.

Use file paths, component names, commands, and test expectations. Give it enough context to navigate, but do not paste the whole repository into one instruction file.

Recommended pattern for this repo:

- Use a short top-level instruction file for navigation.
- Put domain knowledge in `docs/`.
- Keep install instructions close to the feature they configure, such as `hooks/README.md`.
- Update docs when the implementation changes so the knowledge base does not drift.

## Validation rules

Before treating Codex extension work as done, validate each layer on its own.

- Confirm the manifest or config file is syntactically valid.
- Confirm discovery works the way the surface expects.
- Confirm hook behavior with a real local run when possible.
- Keep plugin packaging, MCP setup, and hook execution tests separate.
- If the change affects repository behavior, run the relevant project checks after the edit.

## MemPalace-specific references

- Hook install and configuration: `hooks/README.md`
- Save hook implementation: `hooks/mempal_save_hook.sh`
- Pre-compaction hook implementation: `hooks/mempal_precompact_hook.sh`
- Session start hook implementation: `hooks/mempal_session_start_hook.sh`
- Codex JSONL import flow: `scripts/import_codex_recent_jsonl.sh`

## Research sources

Official OpenAI sources used for this summary:

- [Introducing Codex](https://openai.com/index/introducing-codex/)
- [How OpenAI uses Codex](https://openai.com/business/guides-and-resources/how-openai-uses-codex/)
- [Harness engineering: leveraging Codex in an agent-first world](https://openai.com/index/harness-engineering/)
- [Codex web documentation](https://developers.openai.com/codex/cloud)
- [Docs MCP](https://developers.openai.com/learn/docs-mcp)
- [GPT-5.3-Codex model reference](https://developers.openai.com/api/docs/models/gpt-5.3-codex)

## Condensed takeaways from the research

- Codex works best when repository guidance is short, specific, and layered.
- Long-lived knowledge should move into structured docs rather than a giant instruction file.
- Prompts should read like implementation issues: include file paths, constraints, and expected validation.
- Keep runtime automation deterministic and local unless a remote integration is the point.
- Model choice matters less than task shape, but the current Codex models support long context and configurable reasoning effort, which makes structured repo guidance more valuable.
