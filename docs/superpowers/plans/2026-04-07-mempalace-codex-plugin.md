# MemPalace Codex Plugin Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Package MemPalace as a verified Codex installation path with fast install, minimal configuration, and one reusable runtime contract.

**Architecture:** Start by confirming the real Codex plugin and discovery contract, then reuse the existing MemPalace memory engine, hooks, and MCP server. Keep one shared runtime helper for bootstrap and env resolution, and do not duplicate a second wrapper tree unless the verified Codex surface requires it. Separate the contract doc, installer, runtime helpers, docs, and tests so installability and behavior can be verified independently.

**Tech Stack:** Bash, Python 3.9+, pytest, JSON, existing MemPalace CLI/MCP/hook scripts, official Codex plugin docs.

---

## Files & Responsibilities

- Create: `docs/codex-plugin-contract.md`
- Create: `scripts/plugin-runtime.sh`
- Create: `scripts/install-codex-plugin.sh`
- Create: `.codex-plugin/plugin.json`
- Modify: `scripts/plugin-bootstrap.sh`
- Modify: `scripts/plugin-env.sh`
- Modify: `scripts/plugin-session-start-hook.sh`
- Modify: `scripts/plugin-save-hook.sh`
- Modify: `scripts/plugin-precompact-hook.sh`
- Modify: `scripts/plugin-mcp-server.sh`
- Modify: `hooks/README.md`
- Modify: `README.md`
- Modify: `docs/codex-plugin-spec.md`
- Modify: `docs/README.md`
- Test: `tests/test_codex_plugin_contract.py`
- Test: `tests/test_plugin_runtime.py`
- Test: `tests/test_codex_plugin_install.py`
- Test: `tests/test_codex_plugin_docs.py`

The current Claude package already has `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `scripts/plugin-bootstrap.sh`, `scripts/plugin-env.sh`, and thin hook wrappers. Treat that as a surface-specific package, not proof that Codex should use the same manifest shape.

## Task 0: Lock the Codex contract before writing implementation

**Files:**
- Create: `docs/codex-plugin-contract.md`
- Test: `tests/test_codex_plugin_contract.py`
- Modify: `docs/codex-plugin-spec.md`

- [ ] **Step 1: Write the failing contract test**

Create `tests/test_codex_plugin_contract.py`:

```python
from pathlib import Path


def test_codex_contract_doc_has_verified_sections():
    repo = Path(__file__).resolve().parents[1]
    contract = (repo / "docs" / "codex-plugin-contract.md").read_text()

    assert "Required package entrypoint" in contract
    assert "Discovery location" in contract
    assert "Supported manifest fields" in contract
    assert "Unsupported assumptions removed" in contract
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
./.venv/bin/python -m pytest tests/test_codex_plugin_contract.py -v
```

Expected: fail because the contract doc does not exist yet.

- [ ] **Step 3: Write the contract doc**

Create `docs/codex-plugin-contract.md` with these sections:

```markdown
# Codex Plugin Contract

## Required package entrypoint
## Discovery location
## Supported manifest fields
## Surface-specific fields
## Shared runtime fields
## Unsupported assumptions removed
```

Populate it from official Codex docs and current repo state. The key output is the actual discovery and manifest contract, not a guess.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
./.venv/bin/python -m pytest tests/test_codex_plugin_contract.py -v
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add docs/codex-plugin-contract.md docs/codex-plugin-spec.md tests/test_codex_plugin_contract.py
git commit -m "docs: lock codex plugin contract"
```

## Task 1: Factor the shared runtime contract

**Files:**
- Create: `scripts/plugin-runtime.sh`
- Modify: `scripts/plugin-bootstrap.sh`
- Modify: `scripts/plugin-env.sh`
- Modify: `scripts/plugin-session-start-hook.sh`
- Modify: `scripts/plugin-save-hook.sh`
- Modify: `scripts/plugin-precompact-hook.sh`
- Modify: `scripts/plugin-mcp-server.sh`
- Test: `tests/test_plugin_runtime.py`

- [ ] **Step 1: Write the failing runtime test**

Create `tests/test_plugin_runtime.py`:

```python
import os
import subprocess
from pathlib import Path


def test_plugin_bootstrap_resolves_family_specific_data_dir(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    cases = [
        ("CLAUDE_PLUGIN_DATA", "plugin-data"),
        ("CODEX_PLUGIN_DATA", "codex-data"),
    ]

    for env_key, dir_name in cases:
        data_dir = tmp_path / dir_name
        env = os.environ.copy()
        env[env_key] = str(data_dir)

        result = subprocess.run(
            ["bash", "scripts/plugin-bootstrap.sh"],
            cwd=repo,
            env=env,
            capture_output=True,
            text=True,
            check=True,
        )

        assert result.stdout.strip().endswith("venv/bin/python")
        assert (data_dir / "runtime" / "venv" / "bin" / "python").exists()
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
./.venv/bin/python -m pytest tests/test_plugin_runtime.py -v
```

Expected: fail because the shared runtime helper does not yet normalize both prefixes.

- [ ] **Step 3: Write the minimal implementation**

Implement `scripts/plugin-runtime.sh` so it resolves one shared contract:

```bash
plugin_root="${PLUGIN_ROOT:-${CLAUDE_PLUGIN_ROOT:-${CODEX_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}}}"
plugin_data="${PLUGIN_DATA:-${CLAUDE_PLUGIN_DATA:-${CODEX_PLUGIN_DATA:-$HOME/.mempalace/plugin-data}}}"
```

Then update the existing Claude scripts to source that helper. Keep the wrapper count low. Do not create a second family of nearly identical Codex wrapper scripts unless the contract doc proves a separate entrypoint is required.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
./.venv/bin/python -m pytest tests/test_plugin_runtime.py -v
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add scripts/plugin-runtime.sh scripts/plugin-bootstrap.sh scripts/plugin-env.sh scripts/plugin-*.sh tests/test_plugin_runtime.py
git commit -m "feat: factor shared plugin runtime"
```

## Task 2: Add the Codex package and installation layer

**Files:**
- Create: `.codex-plugin/plugin.json`
- Create: `scripts/install-codex-plugin.sh`
- Test: `tests/test_codex_plugin_install.py`

- [ ] **Step 1: Write the failing install test**

Create `tests/test_codex_plugin_install.py`:

```python
import json
import os
import subprocess
from pathlib import Path


def test_codex_plugin_install_creates_manifest_in_verified_location(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    env = os.environ.copy()
    env["HOME"] = str(tmp_path)
    env["CODEX_PLUGIN_ROOT"] = str(repo)

    result = subprocess.run(
        ["bash", "scripts/install-codex-plugin.sh"],
        cwd=repo,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )

    assert "plugin.json" in result.stdout
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
./.venv/bin/python -m pytest tests/test_codex_plugin_install.py -v
```

Expected: fail because the installer does not exist yet.

- [ ] **Step 3: Write the minimal implementation**

Create `.codex-plugin/plugin.json` using only the fields confirmed in Task 0. Keep it minimal. If the contract doc says Codex supports additional metadata, add only the fields that help discovery or install surfaces. Do not copy the Claude manifest blindly.

Write `scripts/install-codex-plugin.sh` so it installs or links the Codex manifest into the discovery location confirmed by Task 0. If the location is repo-local, write there. If it is user-local, write there. The installer should make the package discoverable without requiring manual file copying.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
./.venv/bin/python -m pytest tests/test_codex_plugin_install.py -v
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add .codex-plugin/plugin.json scripts/install-codex-plugin.sh tests/test_codex_plugin_install.py
git commit -m "feat: add codex plugin install layer"
```

## Task 3: Update docs and keep docs/tests separate

**Files:**
- Modify: `hooks/README.md`
- Modify: `README.md`
- Modify: `docs/codex-plugin-spec.md`
- Modify: `docs/README.md`
- Test: `tests/test_codex_plugin_docs.py`

- [ ] **Step 1: Write the failing docs test**

Create `tests/test_codex_plugin_docs.py`:

```python
from pathlib import Path


def test_codex_install_path_is_documented_separately():
    repo = Path(__file__).resolve().parents[1]
    hooks_readme = (repo / "hooks" / "README.md").read_text()
    root_readme = (repo / "README.md").read_text()
    spec = (repo / "docs" / "codex-plugin-spec.md").read_text()

    assert "Codex" in hooks_readme
    assert "Codex plugin" in root_readme
    assert "fast-install" in spec
```

- [ ] **Step 2: Run the test to verify it fails**

Run:

```bash
./.venv/bin/python -m pytest tests/test_codex_plugin_docs.py -v
```

Expected: fail until the docs mention the verified Codex path clearly.

- [ ] **Step 3: Update the docs**

Update `hooks/README.md` so it distinguishes:

- manual Claude install
- the verified Codex install path
- shared runtime assets that both paths reuse

Update `README.md` so the plugin story is discoverable from the top level, with one short sentence pointing to the spec, the contract doc, and the installer.

Keep `docs/codex-plugin-spec.md` aligned with the implementation, and keep `docs/codex-plugin-contract.md` aligned with the verified Codex surface. The spec explains the product. The contract doc explains the actual supported surface.

- [ ] **Step 4: Run the test to verify it passes**

Run:

```bash
./.venv/bin/python -m pytest tests/test_codex_plugin_docs.py -v
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add README.md hooks/README.md docs/codex-plugin-spec.md docs/codex-plugin-contract.md docs/README.md tests/test_codex_plugin_docs.py
git commit -m "docs: document codex plugin install path"
```

## Task 4: End-to-end smoke test the verified install path

**Files:**
- Modify: `tests/test_codex_plugin_install.py`
- Modify: `tests/test_plugin_runtime.py`
- Possibly modify: `scripts/install-codex-plugin.sh` if the smoke test exposes path issues

- [ ] **Step 1: Write the failing smoke test**

Extend `tests/test_codex_plugin_install.py` with a clean-environment smoke path:

```python
def test_codex_plugin_smoke(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    env = os.environ.copy()
    env["HOME"] = str(tmp_path)
    env["CODEX_PLUGIN_ROOT"] = str(repo)
    env["CODEX_PLUGIN_DATA"] = str(tmp_path / "codex-data")

    install = subprocess.run(
        ["bash", "scripts/install-codex-plugin.sh"],
        cwd=repo,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )

    assert "plugin.json" in install.stdout

    hook = subprocess.run(
        ["bash", "scripts/plugin-session-start-hook.sh"],
        cwd=repo,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )

    assert hook.returncode == 0
```

- [ ] **Step 2: Run the smoke test and confirm it fails before wiring is complete**

Run:

```bash
./.venv/bin/python -m pytest tests/test_codex_plugin_install.py tests/test_plugin_runtime.py tests/test_codex_plugin_docs.py -v
```

Expected: fail until the installer, manifest, and runtime helpers are all wired together.

- [ ] **Step 3: Finish the wiring**

Make sure the installer, manifest, and runtime helpers all agree on:

- the verified discovery location
- the plugin root
- the data dir
- the hook entrypoints

Do not add a second Codex-specific wrapper tree unless Task 0 proved it is required.

- [ ] **Step 4: Run the smoke test and full repo checks**

Run:

```bash
./.venv/bin/python -m pytest -v
./.venv/bin/ruff check .
```

Expected: all tests pass and lint is clean.

- [ ] **Step 5: Commit**

```bash
git add scripts/install-codex-plugin.sh .codex-plugin/plugin.json tests/test_codex_plugin_install.py tests/test_plugin_runtime.py
git commit -m "feat: validate codex plugin smoke path"
```

## Self-Review

### 1. Spec coverage

- Fast first use: Tasks 1, 2, and 4 create the verified install path and smoke-test it.
- Near-zero configuration: Task 2 adds an installer only after Task 0 verifies the discovery surface.
- One entry point: Task 1 keeps shared runtime behavior in one place instead of cloning wrapper trees.
- Deterministic behavior: Task 1 keeps the runtime local and venv-backed; Task 4 proves it in a clean environment.
- Easy verification: Tasks 0-4 all have explicit checks and separate docs/tests boundaries.

### 2. Placeholder scan

This revision removes the old `.codex-plugin/marketplace.json` assumption and replaces it with a contract-first step. Each task now names a concrete artifact or a contract doc that resolves the remaining uncertainty.

### 3. Type consistency

The plan now uses one runtime contract, one installer, and one verified Codex manifest. Claude-specific surface files stay where they are until the contract doc says otherwise.

### Gaps to watch during implementation

- If Task 0 shows that Codex discovery is user-local instead of repo-local, update only the installer and contract doc, not the runtime helpers.
- If Codex requires a distinct manifest field set, keep the manifest minimal and move unsupported behavior out of the package.

