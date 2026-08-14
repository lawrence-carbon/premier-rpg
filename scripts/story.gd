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
## true = menu pause ouvert
var menu_open := false

var intro_done := false
var quest_active := false
var quest_text := ""

## Étapes : none → forest → narek → grak_done → crypt → crystal_done
##          → mira → col → valley_done
var stage := "none"
var narek_joined := false
var has_key := false
var crystal_found := false
var mira_talked := false
var voiled_seen := false
## true = le joueur conduit l'automobile
var in_vehicle := false


func lock_for_ui() -> void:
	ui_locked = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	dialogue_opened.emit()


func unlock_from_ui() -> void:
	ui_locked = false
	if not menu_open and not map_open:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	dialogue_closed.emit()


func can_control_player() -> bool:
	return not ui_locked and not menu_open


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


func give_key() -> void:
	has_key = true
	set_stage("grak_done")
	set_quest("Ouvre la Crypte oubliée avec la clé (pied de la colline, au nord du camp)")


func find_crystal() -> void:
	crystal_found = true
	set_stage("crystal_done")
	set_quest("Sors de la crypte, puis retourne à Boisclair parler à Alden")


func send_to_mira() -> void:
	set_stage("mira")
	set_quest("Parle à Mira devant l'église de Boisclair")


func finish_mira() -> void:
	mira_talked = true
	set_stage("col")
	set_quest("Va au Col de l'Aube (ouest) — quelque chose t'y attend")


func see_voiled() -> void:
	voiled_seen = true
	set_stage("valley_done")
	set_quest("La Vallée d'Aube a livré son secret… Eldoria t'attend")


func to_dict() -> Dictionary:
	return {
		"intro_done": intro_done,
		"quest_active": quest_active,
		"quest_text": quest_text,
		"stage": stage,
		"narek_joined": narek_joined,
		"has_key": has_key,
		"crystal_found": crystal_found,
		"mira_talked": mira_talked,
		"voiled_seen": voiled_seen,
	}


func from_dict(data: Dictionary) -> void:
	intro_done = bool(data.get("intro_done", false))
	quest_active = bool(data.get("quest_active", false))
	quest_text = str(data.get("quest_text", ""))
	stage = str(data.get("stage", "none"))
	narek_joined = bool(data.get("narek_joined", false))
	has_key = bool(data.get("has_key", false))
	crystal_found = bool(data.get("crystal_found", false))
	mira_talked = bool(data.get("mira_talked", false))
	voiled_seen = bool(data.get("voiled_seen", false))
	# Anciennes sauvegardes : après Grak sans flag has_key
	if stage in ["grak_done", "crypt", "crystal_done", "mira", "col", "valley_done"] or crystal_found:
		has_key = true
	if stage in ["col", "valley_done"] or mira_talked:
		mira_talked = true
	if stage == "valley_done" or voiled_seen:
		voiled_seen = true
	if narek_joined:
		companion_changed.emit(true)
	if quest_active:
		quest_updated.emit(quest_text)
	stage_changed.emit(stage)


func reset() -> void:
	ui_locked = false
	map_open = false
	menu_open = false
	intro_done = false
	quest_active = false
	quest_text = ""
	stage = "none"
	narek_joined = false
	has_key = false
	crystal_found = false
	mira_talked = false
	voiled_seen = false
	in_vehicle = false
	companion_changed.emit(false)
