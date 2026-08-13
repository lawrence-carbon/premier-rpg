extends Node

## État de l'histoire (autoload).

signal quest_updated(text: String)
signal dialogue_opened
signal dialogue_closed
signal companion_changed(active: bool)
signal stage_changed(stage: String)

## true = panneau ouvert → on ne bouge plus
var ui_locked := false
## true = la carte complète est ouverte
var map_open := false

var intro_done := false
var quest_active := false
var quest_text := ""

## Étapes : none → forest → narek → camp → grak_done
var stage := "none"
var narek_joined := false


func lock_for_ui() -> void:
	ui_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	dialogue_opened.emit()


func unlock_from_ui() -> void:
	ui_locked = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	dialogue_closed.emit()


func can_control_player() -> bool:
	return not ui_locked


func set_quest(text: String) -> void:
	quest_active = true
	quest_text = text
	quest_updated.emit(text)


func set_stage(new_stage: String) -> void:
	stage = new_stage
	stage_changed.emit(stage)


func join_narek() -> void:
	narek_joined = true
	companion_changed.emit(true)
