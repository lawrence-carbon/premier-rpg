extends Node3D

## Entrée des ruines : s'ouvre avec la clé de Grak.

@onready var interact_area: Area3D = $InteractArea
@onready var door_mesh: MeshInstance3D = $Door

var _player_near := false
var _story_ui: CanvasLayer
var _opened := false

const CRYPT_SPAWN := Vector3(132.3, -29.8, -102)
const INTERACT_DIST := 4.5


func _ready() -> void:
	add_to_group("crypt_entrance")
	add_to_group("interactable")
	interact_area.monitoring = true
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	call_deferred("_find_ui")
	# Si une vieille sauvegarde a déjà battu Grak sans has_key
	if Story.stage == "grak_done" or Story.stage == "crypt" or Story.crystal_found:
		Story.has_key = true
	_update_door_visual()


func _find_ui() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")


func _physics_process(_delta: float) -> void:
	# Détection de secours par distance (plus fiable que l'Area seule)
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	var near_now := dist <= INTERACT_DIST
	if near_now and not _player_near:
		_player_near = true
		_show_prompt()
	elif not near_now and _player_near:
		_player_near = false
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(false)


func _input(event: InputEvent) -> void:
	# _input passe AVANT les autres PNJ (Narek) → E ouvre bien la crypte
	if not _player_near or not Story.can_control_player():
		return
	if event.is_action_pressed("interact"):
		_try_open()
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		_show_prompt()


func _on_body_exited(body: Node3D) -> void:
	# La distance dans _physics_process gère la sortie
	pass


func _can_unlock() -> bool:
	return Story.has_key or Story.crystal_found or Story.stage in ["grak_done", "crypt", "crystal_done"]


func _show_prompt() -> void:
	if _story_ui == null or not _story_ui.has_method("show_interact_prompt"):
		return
	if Story.crystal_found or _opened:
		_story_ui.show_interact_prompt(true, "Entrer dans la crypte [E]")
	elif _can_unlock():
		_story_ui.show_interact_prompt(true, "Ouvrir avec la clé [E]")
	else:
		_story_ui.show_interact_prompt(true, "Ruines verrouillées (il faut la clé de Grak)")


func _try_open() -> void:
	if _story_ui == null:
		_story_ui = get_tree().get_first_node_in_group("story_ui")
	if _story_ui == null:
		return
	if _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)

	if not _can_unlock():
		_story_ui.start_dialogue("Ruines", PackedStringArray([
			"Une vieille porte de pierre…",
			"Elle est scellée. Il faut la clé de Grak.",
		]))
		return

	Story.has_key = true

	if not _opened:
		_story_ui.start_dialogue(
			"Narek" if Story.narek_joined else "Héros",
			PackedStringArray([
				"La clé tourne… la porte s'ouvre.",
				"Personne à Boisclair ne parlait de cet endroit.",
				"Descendons. Reste prudent.",
			]),
			_enter_crypt
		)
	else:
		_enter_crypt()


func _enter_crypt() -> void:
	_opened = true
	_update_door_visual()
	Story.set_stage("crypt")
	if not Story.crystal_found:
		Story.set_quest("Explore la Crypte oubliée — trouve le cristal")

	var player := get_tree().get_first_node_in_group("player") as Node3D
	var narek := get_tree().get_first_node_in_group("narek") as Node3D
	if player:
		player.global_position = CRYPT_SPAWN
		player.velocity = Vector3.ZERO
		player.rotation.y = PI
	if narek and Story.narek_joined:
		narek.global_position = CRYPT_SPAWN + Vector3(-1.5, 0, 1.2)


func _update_door_visual() -> void:
	if door_mesh == null:
		return
	if _opened or _can_unlock():
		door_mesh.rotation_degrees.y = -75.0
	else:
		door_mesh.rotation_degrees.y = 0.0


func get_save_data() -> Dictionary:
	return {"opened": _opened}


func apply_save_data(data: Dictionary) -> void:
	_opened = bool(data.get("opened", false))
	if Story.stage == "grak_done" or Story.stage == "crypt" or Story.crystal_found:
		Story.has_key = true
	_update_door_visual()
