# Codex Plugin Spec for MemPalace

## 1. Purpose

MemPalace should be deliverable as a Codex plugin package that makes agent memory available with the shortest possible setup path.

The plugin is not just a wrapper around existing scripts. It is the productized delivery surface for MemPalace:

- install fast
- work with minimal configuration
- keep memory behavior deterministic and local
- make the current repository knowledge available to Codex immediately
- give users a single place to discover, install, and update the memory stack

## 2. Core Value

This spec is built around five values.

### 2.1 Fast first use

The first successful installation should take the fewest possible steps. Users should not need to understand the full repository structure before getting value.

### 2.2 Near-zero configuration

The plugin should ship with safe defaults. Any required manual step must be small, explicit, and easy to finish.

### 2.3 One entry point

Hooks, startup context, import flow, and repo guidance should be packaged as one unit rather than scattered across scripts and README files.

### 2.4 Deterministic behavior

Memory capture, startup context, and checkpointing should remain local, predictable, and easy to reason about. The plugin should not depend on hidden remote behavior.

### 2.5 Easy verification

The package should be testable after install. Users and maintainers should be able to prove that the plugin works, not just assume it works.

## 3. Problem Statement

Agent work loses context in predictable places:

- when a session ends
- when context compacts
- when the user switches tools or machines
- when decisions live only in chat history

MemPalace already solves the memory model. The missing piece is delivery:

- the current experience requires too much manual assembly
- installation knowledge is split across docs, hooks, and scripts
- the memory stack is not packaged as a product-level Codex extension

## 4. Goals

- Make MemPalace installable as a Codex plugin package.
- Reduce initial setup friction to the smallest practical sequence.
- Provide sane defaults for hooks, startup context, and import flows.
- Keep the install boundary separate from runtime behavior.
- Make the plugin discoverable and updateable as one unit.

## 5. Non-Goals

- Rewriting the memory model itself.
- Changing the Palace data model just to fit the plugin boundary.
- Making hooks network-dependent.
- Supporting every AI platform in the first plugin version.
- Building a general plugin framework for unrelated projects.

## 6. Target User Experience

The intended experience is:

1. User installs the plugin.
2. The plugin installs or links the minimal required MemPalace runtime pieces.
3. The plugin enables Codex-facing hooks and startup context with defaults.
4. The user can immediately start working with memory support.
5. The user can import existing conversations or project context later, without redoing setup.

The key outcome is that MemPalace feels like a ready-made capability, not a custom integration project.

## 7. Functional Requirements

### 7.1 Installation

- The plugin must be installable with a short command path.
- The plugin must bundle the files needed for first use.
- The plugin must expose a predictable layout so future updates can be versioned.

### 7.2 Default configuration

- The plugin must provide safe defaults for Codex-facing hooks.
- The plugin must not require users to edit repository files for the first run.
- Machine-specific values must stay outside the shared package or be generated at install time.

### 7.3 Startup context

- The plugin must provide a startup or wake-up path that gives Codex the current memory baseline.
- The startup context must point to the same Palace concepts used by the core repository.

### 7.4 Memory capture

- The plugin must preserve the current save and pre-compact behaviors.
- The plugin must keep checkpoint behavior deterministic.
- The plugin must not re-import full transcripts when a smaller checkpoint is enough.

### 7.5 Import flow

- The plugin must expose the existing import workflow in a way users can discover quickly.
- The plugin must support conversation import without forcing extra configuration first.

### 7.6 Update path

- The plugin must be versioned.
- The plugin must allow future upgrades without redoing the whole install flow.
- The plugin should preserve backward compatibility where possible.

## 8. Packaging Rules

The plugin package should keep concerns separated.

### 8.1 Package boundary

- Plugin manifest: source of truth for installable metadata.
- Runtime hooks: deterministic local scripts.
- Repository guidance: docs and reference material.
- Import tools: scripts that can be called after install.

### 8.2 What belongs in the plugin

- Codex-facing metadata
- hook wiring
- startup context entry point
- versioned package information
- install-time defaults

### 8.3 What stays in the repo

- deep implementation detail
- memory model internals
- long-form documentation
- import scripts that are also useful without the plugin
- developer notes and research context

## 9. Required User Flows

### 9.1 Fresh install

User installs the plugin and gets a working memory baseline with minimal follow-up.

### 9.2 First working session

User opens Codex and immediately benefits from startup context and checkpoint behavior.

### 9.3 Existing data import

User can later import existing conversation history or project memory into MemPalace.

### 9.4 Update and upgrade

User can upgrade the plugin without losing the established memory structure.

## 10. Success Metrics

The plugin is successful if it reduces:

- setup steps
- time to first useful memory baseline
- amount of manual config the user must edit
- number of install-time failures
- number of “I installed it but nothing happened” cases

The plugin is also successful if it increases:

- discoverability
- repeatability across machines
- confidence that the memory stack is active

## 11. Risks

- Over-packaging could hide the useful internals and make debugging harder.
- Too much automation could make first-run behavior feel magical but opaque.
- A plugin boundary that is too broad could duplicate repo logic.
- A plugin boundary that is too narrow could still force too much manual setup.

## 12. Acceptance Criteria

- The plugin story can be explained in one short paragraph.
- A new user can identify the install path without reading multiple docs.
- The plugin has a clear package boundary and a clear runtime boundary.
- The existing hooks and import flow still work as the underlying implementation.
- The package supports versioned updates.
- The repo has a written spec that can be used to implement the plugin without re-deciding the product shape.

## 13. Open Questions

- What exact packaging format will Codex use for the plugin surface in this repo?
- Which parts of the install can be automated safely on first run?
- How much of the startup context should be generated versus committed?
- What compatibility guarantees should the plugin make across future Codex versions?

## 14. Next Implementation Slice

The next concrete step is to turn this spec into a plugin package plan:

- define the file layout
- define the install command path
- define the generated defaults
- define the validation check after install

