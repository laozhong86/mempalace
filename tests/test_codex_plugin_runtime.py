import os
import subprocess
from pathlib import Path


def test_plugin_bootstrap_resolves_codex_and_claude_env_vars(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    cases = [
        ("CLAUDE_PLUGIN_ROOT", "CLAUDE_PLUGIN_DATA", "claude-data"),
        ("CODEX_PLUGIN_ROOT", "CODEX_PLUGIN_DATA", "codex-data"),
    ]

    for root_env, data_env, dir_name in cases:
        plugin_data = tmp_path / dir_name
        env = os.environ.copy()
        env[root_env] = str(repo)
        env[data_env] = str(plugin_data)

        result = subprocess.run(
            ["bash", "scripts/plugin-bootstrap.sh"],
            cwd=repo,
            env=env,
            capture_output=True,
            text=True,
            check=True,
        )

        assert result.stdout.strip().endswith("venv/bin/python")
        assert (plugin_data / "runtime" / "venv" / "bin" / "python").exists()
