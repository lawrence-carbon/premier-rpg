extends Node3D

## Porte d'un bâtiment : E pour entrer dans l'intérieur partagé.

@export var building_name := "Maison"
@export var interact_dist := 3.2

var _player_near := false
var _story_ui: CanvasLayer


func _ready() -> void:
	add_to_group("building_door")
	add_to_group("interactable")
	call_deferred("_find_ui")
	if has_node("Label"):
		$Label.text = building_name


func _find_ui() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")


func _physics_process(_delta: float) -> void:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	# Pas d'entrée si on est déjà sous terre (intérieur)
	if player.global_position.y < -5.0:
		if _player_near:
			_player_near = false
			if _story_ui and _story_ui.has_method("show_interact_prompt"):
				_story_ui.show_interact_prompt(false)
		return
	var dist := global_position.distance_to(player.global_position)
	var near_now := dist <= interact_dist
	if near_now and not _player_near:
		_player_near = true
		_show_prompt()
	elif not near_now and _player_near:
		_player_near = false
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(false)


func _input(event: InputEvent) -> void:
	if not _player_near or not Story.can_control_player():
		return
	if event.is_action_pressed("interact"):
		_enter()
		get_viewport().set_input_as_handled()


func _show_prompt() -> void:
	if _story_ui and _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(true, "Entrer : %s [E]" % building_name)


func _enter() -> void:
	if _story_ui and _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)
	var interior := get_tree().get_first_node_in_group("building_interior")
	if interior and interior.has_method("enter"):
		# Point de sortie juste devant la porte
		var outside := global_position + global_transform.basis.z * 2.0
		outside.y = 0.2
		interior.enter(building_name, outside, rotation.y)
