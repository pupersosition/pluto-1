from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_mass_defeat_uses_collapse_game_over_path():
    source = (ROOT / "scripts" / "main.gd").read_text()
    assert "_game_over(true)" in source


def test_warp_defeat_does_not_use_collapse_animation_path():
    source = (ROOT / "scripts" / "main.gd").read_text()
    warp_handler = source.split("func _on_warp_player_consumed()", 1)[1].split("func _on_warp_closed", 1)[0]
    assert "_game_over(false)" in warp_handler
    assert "_game_over(true)" not in warp_handler


def test_game_over_triggers_collapse_effect_and_delays_restart_prompt():
    source = (ROOT / "scripts" / "main.gd").read_text()
    game_over = source.split("func _game_over", 1)[1].split("func _try_activate_perk", 1)[0]
    assert "play_collapse_animation" in game_over
    assert "collapse_for_game_over" in game_over
    assert "create_timer" in game_over
    assert "show_restart_prompt" in game_over


def test_player_exposes_collapse_hide_api():
    source = (ROOT / "scripts" / "player_blob.gd").read_text()
    assert "func collapse_for_game_over() -> void:" in source
    method_body = source.split("func collapse_for_game_over() -> void:", 1)[1].split("func is_defeated", 1)[0]
    assert "input_enabled = false" in method_body
    assert "velocity = Vector2.ZERO" in method_body
    assert "blob_visual.visible = false" in method_body


def test_collapse_burst_effect_exists_and_is_wired_into_main_scene():
    effect_path = ROOT / "scripts" / "collapse_burst.gd"
    assert effect_path.exists()
    effect_source = effect_path.read_text()
    assert "func play_burst(origin: Vector2, gravity_direction: float, blob_scale: Vector2) -> void:" in effect_source
    assert "queue_redraw()" in effect_source
    assert "SQUASH_DURATION" in effect_source
    assert "_draw_squash" in effect_source

    scene_source = (ROOT / "scenes" / "main.tscn").read_text()
    assert "collapse_burst.gd" in scene_source
    assert "CollapseBurst" in scene_source
