import os
import shutil
import subprocess
from pathlib import Path

import pytest


@pytest.mark.integration
def test_first_run_install_from_fresh_home(tmp_path):
    if shutil.which("claude") is None:
        pytest.skip("claude CLI is not installed")

    repo = Path(__file__).resolve().parents[1]
    env = os.environ.copy()
    env["HOME"] = str(tmp_path)
    env["PATH"] = os.environ["PATH"]

    add_marketplace = subprocess.run(
        ["claude", "plugin", "marketplace", "add", str(repo)],
        cwd=repo,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    assert "added" in add_marketplace.stdout.lower()

    install = subprocess.run(
        ["claude", "plugin", "install", "mempalace@mempalace-dev", "--scope", "local"],
        cwd=repo,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )
    assert "installed" in install.stdout.lower()

    doctor = subprocess.run(
        ["bash", "plugins/claude/mempalace/scripts/plugin-doctor.sh"],
        cwd=repo,
        env={**env, "CLAUDE_PLUGIN_ROOT": str(repo / "plugins" / "claude" / "mempalace")},
        capture_output=True,
        text=True,
        check=True,
    )
    assert "runtime_python=" in doctor.stdout
