import json
from pathlib import Path


def test_codex_plugin_manifest_matches_contract():
    repo = Path(__file__).resolve().parents[1]
    manifest = json.loads((repo / ".codex-plugin" / "plugin.json").read_text())

    assert manifest["name"] == "mempalace"
    assert manifest["mcpServers"] == "./.mcp.json"
    assert manifest["interface"]["displayName"] == "MemPalace"
    assert manifest["interface"]["shortDescription"] == "Local memory for Codex"
    assert "mcp" in manifest["keywords"]
