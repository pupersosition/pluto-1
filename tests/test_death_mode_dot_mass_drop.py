from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_player_exposes_death_mode_dot_mass_drop_equal_to_mass_release_perk():
    source = (ROOT / "scripts" / "player_blob.gd").read_text()
    assert "func drop_mass_from_death_mode_dot() -> void:" in source
    helper_body = source.split("func drop_mass_from_death_mode_dot() -> void:", 1)[1].split("\n\n", 1)[0]
    assert "mass = maxf(1.0, mass - MASS_RELEASE_AMOUNT)" in helper_body
    assert "_update_visual_scale()" in helper_body


def test_dot_uses_death_mode_path_and_spawns_local_feedback_before_freeing():
    source = (ROOT / "scripts" / "dot.gd").read_text()
    assert 'preload("res://scripts/death_mode_mass_drop_feedback.gd")' in source
    assert "func _spawn_death_mode_mass_drop_feedback(origin: Vector2) -> void:" in source
    handler = source.split("func _on_body_entered(body: Node) -> void:", 1)[1]
    assert "var eaten_position := global_position" in handler
    assert "body.has_method(\"is_death_mode_active\")" in handler
    assert "body.has_method(\"drop_mass_from_death_mode_dot\")" in handler
    assert "body.call(\"drop_mass_from_death_mode_dot\")" in handler
    assert "_spawn_death_mode_mass_drop_feedback(eaten_position)" in handler
    assert "body.call(\"absorb_dot\", absorb_amount)" in handler
    assert handler.index("drop_mass_from_death_mode_dot") < handler.index("queue_free()")


def test_feedback_effect_contains_mass_release_style_particles_and_pixel_text():
    path = ROOT / "scripts" / "death_mode_mass_drop_feedback.gd"
    assert path.exists()
    source = path.read_text()
    assert "extends Node2D" in source
    assert "const DURATION := 0.55" in source
    assert "const PARTICLE_COUNT := 34" in source
    assert "const DOT_SIZE := 4.0" in source
    assert "func play(origin: Vector2) -> void:" in source
    assert 'draw_string(font, text_position, "mass dropped!"' in source
    assert "queue_free()" in source
