extends Node3D

## Intérieur partagé des bâtiments de Boisclair (sous le village).

const INTERIOR_SPAWN := Vector3(0, 0.2, 4.5)
const EXIT_DIST := 3.5

@onready var title_label: Label3D = $TitleLabel

var _story_ui: CanvasLayer
var _player_near_exit := false
var _return_pos := Vector3(-18, 0.2, -18)
var _return_yaw := 0.0
var _inside := false


func _ready() -> void:
	add_to_group("building_interior")
	call_deferred("_find_ui")


func _find_ui() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")


func enter(building_name: String, outside_pos: Vector3, outside_yaw: float = 0.0) -> void:
	_return_pos = outside_pos
	_return_yaw = outside_yaw
	_inside = true
	if title_label:
		title_label.text = building_name

	var player := get_tree().get_first_node_in_group("player") as Node3D
	var narek := get_tree().get_first_node_in_group("narek") as Node3D
	if player:
		player.global_position = global_position + INTERIOR_SPAWN
		player.velocity = Vector3.ZERO
		player.rotation.y = PI
	if narek and Story.narek_joined:
		narek.global_position = global_position + INTERIOR_SPAWN + Vector3(-1.2, 0, 1.0)

	if _story_ui and _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)


func _physics_process(_delta: float) -> void:
	if not _inside:
		return
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var exit_pos := global_position + Vector3(0, 0, 7.5)
	var dist := exit_pos.distance_to(player.global_position)
	var near_now := dist <= EXIT_DIST
	if near_now and not _player_near_exit:
		_player_near_exit = true
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(true, "Sortir [E]")
	elif not near_now and _player_near_exit:
		_player_near_exit = false
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(false)


func _input(event: InputEvent) -> void:
	if not _inside or not _player_near_exit or not Story.can_control_player():
		return
	if event.is_action_pressed("interact"):
		_leave()
		get_viewport().set_input_as_handled()


func _leave() -> void:
	_inside = false
	_player_near_exit = false
	if _story_ui and _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)

	var player := get_tree().get_first_node_in_group("player") as Node3D
	var narek := get_tree().get_first_node_in_group("narek") as Node3D
	if player:
		player.global_position = _return_pos
		player.velocity = Vector3.ZERO
		player.rotation.y = _return_yaw
	if narek and Story.narek_joined:
		narek.global_position = _return_pos + Vector3(-1.5, 0, 1.0)
