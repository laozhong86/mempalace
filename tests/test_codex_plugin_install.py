import json
import os
import subprocess
from pathlib import Path


def test_codex_plugin_install_creates_user_marketplace(tmp_path):
    repo = Path(__file__).resolve().parents[1]
    env = os.environ.copy()
    env["HOME"] = str(tmp_path)

    result = subprocess.run(
        ["bash", "scripts/install-codex-plugin.sh"],
        cwd=repo,
        env=env,
        capture_output=True,
        text=True,
        check=True,
    )

    marketplace_file = tmp_path / ".agents" / "plugins" / "marketplace.json"
    data = json.loads(marketplace_file.read_text())
    plugin = next(entry for entry in data["plugins"] if entry["name"] == "mempalace")

    assert marketplace_file.as_posix() in result.stdout
    assert plugin["source"]["path"] == str(repo.resolve())
