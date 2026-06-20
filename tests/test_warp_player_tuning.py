from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_warp_player_pull_is_more_pronounced_without_changing_other_pull_tuning():
    source = (ROOT / "scripts" / "space_warp.gd").read_text()
    assert "const PLAYER_PULL_STRENGTH := 1950.0" in source
    assert "const MAX_PLAYER_PULL := 1250.0" in source
    assert "const ENEMY_PULL_STRENGTH := 3000.0" in source
    assert "const POWERUP_PULL_STRENGTH := 2200.0" in source
    assert "const MAX_ENEMY_PULL := 2200.0" in source
    assert "const MAX_POWERUP_PULL := 1600.0" in source
