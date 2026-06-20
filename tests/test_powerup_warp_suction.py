from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POWERUP_SCRIPTS = [
    ROOT / "scripts" / "annihilation_star.gd",
    ROOT / "scripts" / "mass_release_star.gd",
    ROOT / "scripts" / "gravity_reverser.gd",
    ROOT / "scripts" / "death_skull.gd",
]


def test_powerups_expose_warp_suction_that_moves_bobbing_anchor():
    for script in POWERUP_SCRIPTS:
        source = script.read_text()
        assert "func apply_warp_suction(" in source, f"{script.name} must expose warp suction API"
        method_body = source.split("func apply_warp_suction(", 1)[1]
        assert "_base_position" in method_body, f"{script.name} suction must update the bobbing anchor"


def test_space_warp_uses_powerup_warp_suction_api():
    source = (ROOT / "scripts" / "space_warp.gd").read_text()
    apply_to_powerups = source.split("func _apply_to_powerups", 1)[1].split("func _apply_pull", 1)[0]
    assert "apply_warp_suction" in apply_to_powerups
