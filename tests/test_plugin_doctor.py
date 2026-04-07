import os
import subprocess
from pathlib import Path


def test_plugin_doctor_checks_real_state(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    package_root = repo / "plugins" / "claude" / "mempalace"
    palace_path = tmp_path / "palace"
    palace_path.mkdir()

    env = os.environ.copy()
    env["CLAUDE_PLUGIN_ROOT"] = str(package_root)
    env["CLAUDE_PLUGIN_DATA"] = str(tmp_path / "plugin-data")
    env["CLAUDE_PLUGIN_OPTION_PALACE_PATH"] = str(palace_path)

    result = subprocess.run(
        ["bash", "plugins/claude/mempalace/scripts/plugin-doctor.sh"],
        cwd=repo,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )

    assert "runtime_python=" in result.stdout
    assert f"palace_path={palace_path}" in result.stdout
    assert "palace_path_exists=yes" in result.stdout
    assert "hooks_executable=yes" in result.stdout
    assert "mcp_import=yes" in result.stdout
    assert "writable_log_dir=yes" in result.stdout
