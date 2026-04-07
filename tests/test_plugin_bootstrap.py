import os
import subprocess
from pathlib import Path


def test_bootstrap_is_concurrency_safe(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    package_root = repo / "plugins" / "claude" / "mempalace"
    env = os.environ.copy()
    env["CLAUDE_PLUGIN_ROOT"] = str(package_root)
    env["CLAUDE_PLUGIN_DATA"] = str(tmp_path / "plugin-data")

    cmd = ["bash", "plugins/claude/mempalace/scripts/plugin-bootstrap.sh"]
    p1 = subprocess.Popen(
        cmd, cwd=repo, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    p2 = subprocess.Popen(
        cmd, cwd=repo, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True
    )
    out1, err1 = p1.communicate(timeout=120)
    out2, err2 = p2.communicate(timeout=120)

    assert p1.returncode == 0, err1
    assert p2.returncode == 0, err2
    assert out1.strip() == out2.strip()
    assert out1.strip().endswith("/runtime/current/bin/python")


def test_runtime_defaults_match_manifest(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    env = os.environ.copy()
    env["CLAUDE_PLUGIN_ROOT"] = str(repo / "plugins" / "claude" / "mempalace")
    env["CLAUDE_PLUGIN_DATA"] = str(tmp_path / "plugin-data")

    result = subprocess.run(
        [
            "bash",
            "-lc",
            "source plugins/claude/mempalace/scripts/plugin-env.sh && "
            "printf '%s|%s|%s' \"$MEMPALACE_PALACE_PATH\" \"$MEMPALACE_STARTUP_WING\" \"$MEMPALACE_SAVE_INTERVAL\"",
        ],
        cwd=repo,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )

    assert result.stdout.strip() == f"{Path.home() / '.mempalace' / 'palace'}|claude|15"
