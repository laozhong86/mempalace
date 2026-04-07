import json
import os
import subprocess
from pathlib import Path


def _plugin_env(repo: Path, tmp_path: Path) -> dict[str, str]:
    env = os.environ.copy()
    env["CLAUDE_PLUGIN_ROOT"] = str(repo / "plugins" / "claude" / "mempalace")
    env["CLAUDE_PLUGIN_DATA"] = str(tmp_path / "plugin-data")
    env["CLAUDE_PLUGIN_OPTION_PALACE_PATH"] = str(tmp_path / "palace")
    (tmp_path / "palace").mkdir()
    return env


def test_packaged_save_hook_allows_stop_when_already_active(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    payload = {"session_id": "s1", "stop_hook_active": True, "transcript_path": ""}

    result = subprocess.run(
        ["bash", "plugins/claude/mempalace/scripts/plugin-save-hook.sh"],
        cwd=repo,
        env=_plugin_env(repo, tmp_path),
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        check=True,
    )

    assert result.stdout.strip() == "{}"


def test_packaged_precompact_hook_blocks_for_save(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    payload = {"session_id": "s2"}

    result = subprocess.run(
        ["bash", "plugins/claude/mempalace/scripts/plugin-precompact-hook.sh"],
        cwd=repo,
        env=_plugin_env(repo, tmp_path),
        input=json.dumps(payload),
        capture_output=True,
        text=True,
        check=True,
    )

    output = json.loads(result.stdout)
    assert output["decision"] == "block"
    assert "COMPACTION IMMINENT" in output["reason"]


def test_packaged_session_start_hook_returns_context_json(tmp_path):
    repo = Path(__file__).resolve().parents[1]

    result = subprocess.run(
        ["bash", "plugins/claude/mempalace/scripts/plugin-session-start-hook.sh"],
        cwd=repo,
        env=_plugin_env(repo, tmp_path),
        capture_output=True,
        text=True,
        check=True,
    )

    output = json.loads(result.stdout)
    additional_context = output["hookSpecificOutput"]["additionalContext"]
    assert output["hookSpecificOutput"]["hookEventName"] == "SessionStart"
    assert "MemPalace workflow is active for this session." in additional_context
