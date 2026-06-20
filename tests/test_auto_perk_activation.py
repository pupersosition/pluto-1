from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def test_main_auto_activates_perks_without_space_input():
    source = (ROOT / "scripts" / "main.gd").read_text()
    assert 'Input.is_action_just_pressed("activate_perk")' not in source
    process_block = source.split("func _process(delta: float) -> void:", 1)[1].split("func _on_spawn_timer_timeout", 1)[0]
    assert "_try_activate_perk()" in process_block


def test_each_perk_activation_shows_correct_popup_text():
    source = (ROOT / "scripts" / "main.gd").read_text()
    assert 'show_perk_popup", "ANNIHILATION!!!"' in source
    assert 'show_perk_popup", "MASS DROPPED!!!"' in source
    assert 'show_perk_popup", "EAT THEM ALL!!!"' in source
    assert 'show_perk_popup", "GRAVITY FLIPPED!!!"' in source


def test_hud_exposes_one_second_center_popup_api():
    source = (ROOT / "scripts" / "hud.gd").read_text()
    assert "@onready var perk_popup_label: Label = $PerkPopupLabel" in source
    assert "func show_perk_popup(value: String) -> void:" in source
    assert "create_timer(1.0)" in source
    assert "perk_popup_label.text = value" in source
    assert "perk_popup_label.visible = true" in source

    scene_source = (ROOT / "scenes" / "hud.tscn").read_text()
    assert '[node name="PerkPopupLabel" type="Label" parent="."]' in scene_source
    assert "horizontal_alignment = 1" in scene_source
    assert "vertical_alignment = 1" in scene_source


def test_space_instruction_removed_from_hud_copy():
    scene_source = (ROOT / "scenes" / "hud.tscn").read_text()
    assert "Space: activate collected perk" not in scene_source
    assert "READY - SPACE" not in scene_source
