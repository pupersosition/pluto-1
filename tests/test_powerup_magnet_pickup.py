from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
POWERUP_SCRIPTS = [
    ROOT / "scripts" / "annihilation_star.gd",
    ROOT / "scripts" / "mass_release_star.gd",
    ROOT / "scripts" / "gravity_reverser.gd",
    ROOT / "scripts" / "death_skull.gd",
]


def test_all_powerups_define_magnet_pickup_tuning():
    for path in POWERUP_SCRIPTS:
        source = path.read_text()
        assert "const MAGNET_RADIUS := 70.0" in source, f"{path.name} must define magnet radius"
        assert "const COLLECT_RADIUS := 18.0" in source, f"{path.name} must define collect radius"
        assert "const MAGNET_SPEED := 420.0" in source, f"{path.name} must define magnet speed"
        assert "var _magnet_target: Node2D" in source, f"{path.name} must track magnet target"


def test_all_powerups_scan_for_player_and_pull_toward_them():
    for path in POWERUP_SCRIPTS:
        source = path.read_text()
        assert "_update_magnet_pickup(delta)" in source, f"{path.name} must update magnet pickup during process"
        assert "func _update_magnet_pickup(delta: float) -> void:" in source, f"{path.name} must expose update helper"
        assert "func _find_magnet_target() -> Node2D:" in source, f"{path.name} must find player target"
        assert 'get_tree().get_first_node_in_group("player")' in source, f"{path.name} must use player group"
        assert "global_position.distance_to(_magnet_target.global_position)" in source, f"{path.name} must measure player distance"
        assert "global_position.move_toward(_magnet_target.global_position, MAGNET_SPEED * delta)" in source, f"{path.name} must move toward player"
        assert "_collect(_magnet_target)" in source, f"{path.name} must collect at close range"


def test_all_powerups_share_collection_helper_with_collision_fallback():
    expected_grant_methods = {
        "annihilation_star.gd": "grant_annihilation_perk",
        "mass_release_star.gd": "grant_mass_release_perk",
        "gravity_reverser.gd": "toggle_gravity",
        "death_skull.gd": "grant_death_perk",
    }
    for path in POWERUP_SCRIPTS:
        source = path.read_text()
        grant_method = expected_grant_methods[path.name]
        assert "func _collect(body: Node) -> void:" in source, f"{path.name} must collect through helper"
        assert f'body.has_method("{grant_method}")' in source, f"{path.name} must still grant the right perk"
        assert "_collect(body)" in source.split("func _on_body_entered", 1)[1], f"{path.name} collision fallback must use collect helper"
        assert "queue_free()" in source.split("func _collect", 1)[1], f"{path.name} must disappear after collection"


def test_player_scene_marks_blob_as_player_group_for_magnet_scan():
    scene_source = (ROOT / "scenes" / "player_blob.tscn").read_text()
    assert 'groups=["player"]' in scene_source
