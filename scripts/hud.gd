extends CanvasLayer

@onready var time_label: Label = $TimeLabel
@onready var record_label: Label = $RecordLabel
@onready var annihilation_label: Label = $AnnihilationLabel
@onready var mass_release_label: Label = $MassReleaseLabel
@onready var restart_label: Label = $RestartLabel


func set_time_text(value: String) -> void:
	time_label.text = value


func set_record_text(value: String) -> void:
	record_label.text = value


func set_annihilation_ready(is_ready: bool) -> void:
	annihilation_label.visible = is_ready


func set_mass_release_ready(is_ready: bool) -> void:
	mass_release_label.visible = is_ready


func show_restart_prompt(visible_state: bool) -> void:
	restart_label.visible = visible_state
