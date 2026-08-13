extends Node3D

## Fragment de cristal au cœur de la crypte.

@onready var interact_area: Area3D = $InteractArea
@onready var crystal_mesh: MeshInstance3D = $Crystal
@onready var light: OmniLight3D = $OmniLight3D

var _player_near := false
var _story_ui: CanvasLayer
var _taken := false


func _ready() -> void:
	add_to_group("crypt_crystal")
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	call_deferred("_find_ui")
	if Story.crystal_found:
		_taken = true
		_set_taken_visual()


func _find_ui() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")


func _process(_delta: float) -> void:
	if _taken or crystal_mesh == null:
		return
	# Légère pulsation
	var t := Time.get_ticks_msec() * 0.004
	crystal_mesh.position.y = 1.2 + sin(t) * 0.08
	crystal_mesh.rotation.y += _delta * 0.6


func _unhandled_input(event: InputEvent) -> void:
	if _taken or not _player_near or not Story.can_control_player():
		return
	if event.is_action_pressed("interact"):
		_touch_crystal()
		get_viewport().set_input_as_handled()


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") and not _taken:
		_player_near = true
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(true, "Toucher le cristal [E]")


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(false)


func _touch_crystal() -> void:
	if _story_ui == null or _taken:
		return
	if _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)

	_story_ui.start_dialogue(
		"Cristal",
		PackedStringArray([
			"Le fragment pulse… une lumière t'enveloppe.",
			"Tu vois sept immenses cristaux, dispersés à travers Eldoria.",
			"Chacun est gardé par une force différente…",
			"Puis une silhouette voilée apparaît dans la vision.",
			"Une voix lointaine : « Les sceaux s'affaiblissent… »",
			"La vision s'éteint. Tu tiens un fragment de Cristal Ancien.",
		]),
		_on_vision_finished
	)


func _on_vision_finished() -> void:
	_taken = true
	_set_taken_visual()
	Story.find_crystal()
	if _story_ui:
		_story_ui.start_dialogue(
			"Narek" if Story.narek_joined else "Héros",
			PackedStringArray([
				"Alors… les gobelins cherchaient ça.",
				"Et quelqu'un d'autre aussi — le Voilé.",
				"Ce n'est plus seulement une affaire de Boisclair.",
				"Le destin d'Eldoria commence ici.",
			])
		)


func _set_taken_visual() -> void:
	if crystal_mesh:
		crystal_mesh.visible = false
	if light:
		light.light_energy = 0.15


func get_save_data() -> Dictionary:
	return {"taken": _taken or Story.crystal_found}


func apply_save_data(data: Dictionary) -> void:
	_taken = bool(data.get("taken", false)) or Story.crystal_found
	if _taken:
		_set_taken_visual()
