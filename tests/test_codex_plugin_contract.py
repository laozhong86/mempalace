from pathlib import Path


def test_codex_contract_doc_has_verified_sections():
    repo = Path(__file__).resolve().parents[1]
    contract = (repo / "docs" / "codex-plugin-contract.md").read_text()

    assert "Required package entrypoint" in contract
    assert "Discovery location" in contract
    assert "Supported manifest fields" in contract
    assert "Unsupported assumptions removed" in contract
