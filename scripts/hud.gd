extends CanvasLayer

signal start_game_requested

@onready var start_screen: Control = $StartScreen
@onready var start_button: Button = $StartScreen/StartButton
@onready var time_label: Label = $TimeLabel
@onready var record_label: Label = $RecordLabel
@onready var annihilation_label: Label = $AnnihilationLabel
@onready var mass_release_label: Label = $MassReleaseLabel
@onready var death_mode_label: Label = $DeathModeLabel
@onready var perk_popup_label: Label = $PerkPopupLabel
@onready var restart_label: Label = $RestartLabel

var _perk_popup_sequence := 0


func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)


func set_time_text(value: String) -> void:
	time_label.text = value


func set_record_text(value: String) -> void:
	record_label.text = value


func set_annihilation_ready(is_ready: bool) -> void:
	annihilation_label.visible = is_ready


func set_mass_release_ready(is_ready: bool) -> void:
	mass_release_label.visible = is_ready


func set_death_mode_ready(is_ready: bool) -> void:
	death_mode_label.visible = is_ready


func set_inverted_colors(active: bool) -> void:
	var primary: Color = Color(0, 0, 0, 1) if active else Color(1, 1, 1, 1)
	var secondary: Color = Color(0.2, 0.2, 0.2, 1) if active else Color(0.75, 0.75, 0.75, 1)
	time_label.add_theme_color_override("font_color", primary)
	record_label.add_theme_color_override("font_color", secondary)
	annihilation_label.add_theme_color_override("font_color", primary)
	mass_release_label.add_theme_color_override("font_color", Color(0, 0.25, 0.38, 1) if active else Color(0.35, 0.9, 1, 1))
	death_mode_label.add_theme_color_override("font_color", primary)
	perk_popup_label.add_theme_color_override("font_color", primary)
	restart_label.add_theme_color_override("font_color", primary)


func show_start_screen(visible_state: bool) -> void:
	start_screen.visible = visible_state
	if visible_state:
		start_button.grab_focus()


func show_restart_prompt(visible_state: bool) -> void:
	restart_label.visible = visible_state


func show_perk_popup(value: String) -> void:
	_perk_popup_sequence += 1
	var sequence := _perk_popup_sequence
	perk_popup_label.text = value
	perk_popup_label.visible = true
	await get_tree().create_timer(1.0).timeout
	if sequence == _perk_popup_sequence:
		perk_popup_label.visible = false


func _on_start_button_pressed() -> void:
	start_game_requested.emit()
