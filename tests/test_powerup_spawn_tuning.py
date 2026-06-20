from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_death_skull_spawn_weight_is_slightly_increased():
    source = (ROOT / "scripts" / "main.gd").read_text()
    assert "const DEATH_SKULL_POWERUP_CHANCE := 0.34" in source
    assert "const MASS_RELEASE_POWERUP_CHANCE := 0.34" in source
    assert "const ANNIHILATION_POWERUP_CHANCE := 0.30" in source
    assert "const GRAVITY_REVERSER_POWERUP_CHANCE := 0.18" in source
