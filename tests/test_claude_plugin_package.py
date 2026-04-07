import os
import subprocess
from pathlib import Path


def test_packaged_plugin_is_self_contained():
    repo = Path(__file__).resolve().parents[1]
    package_root = repo / "plugins" / "claude" / "mempalace"

    assert (package_root / ".claude-plugin" / "plugin.json").is_file()
    assert (package_root / ".claude-plugin" / "marketplace.json").is_file()
    assert (package_root / ".mcp.json").is_file()
    assert (package_root / "pyproject.toml").is_file()
    assert (package_root / "README.md").is_file()
    assert (package_root / "hooks" / "hooks.json").is_file()
    assert (package_root / "hooks" / "mempal_save_hook.sh").is_file()
    assert (package_root / "mempalace" / "mcp_server.py").is_file()
    assert os.access(package_root / "scripts" / "plugin-doctor.sh", os.X_OK)


def test_packaged_doctor_runs_from_package_root(tmp_path):
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
