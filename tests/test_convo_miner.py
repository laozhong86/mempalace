import os
import tempfile
import shutil
import chromadb
from mempalace.convo_miner import mine_convos


def test_convo_mining():
    tmpdir = tempfile.mkdtemp()
    with open(os.path.join(tmpdir, "chat.txt"), "w") as f:
        f.write(
            "> What is memory?\nMemory is persistence.\n\n> Why does it matter?\nIt enables continuity.\n\n> How do we build it?\nWith structured storage.\n"
        )

    palace_path = os.path.join(tmpdir, "palace")
    mine_convos(tmpdir, palace_path, wing="test_convos")

    client = chromadb.PersistentClient(path=palace_path)
    col = client.get_collection("mempalace_drawers")
    assert col.count() >= 2

    # Verify search works
    results = col.query(query_texts=["memory persistence"], n_results=1)
    assert len(results["documents"][0]) > 0

    shutil.rmtree(tmpdir)


def test_convo_mining_with_metadata_overrides():
    tmpdir = tempfile.mkdtemp()
    with open(os.path.join(tmpdir, "chat.txt"), "w") as f:
        f.write(
            "> Why did we keep wing project-only?\nTo keep source separate from the main project partition.\n"
        )

    palace_path = os.path.join(tmpdir, "palace")
    mine_convos(
        tmpdir,
        palace_path,
        wing="gxgen",
        metadata_overrides={
            "project": "gxgen",
            "source_system": "codex",
            "session_id": "session-123",
        },
    )

    client = chromadb.PersistentClient(path=palace_path)
    col = client.get_collection("mempalace_drawers")
    results = col.get(include=["metadatas", "documents"])
    assert results["documents"]
    metadata = results["metadatas"][0]
    assert metadata["wing"] == "gxgen"
    assert metadata["project"] == "gxgen"
    assert metadata["source_system"] == "codex"
    assert metadata["session_id"] == "session-123"

    shutil.rmtree(tmpdir)
