extends Node3D

## Apparition du Voilé au Col de l'Aube (une seule fois).

const TRIGGER_DIST := 8.0

@onready var figure: Node3D = $Figure
@onready var light: OmniLight3D = $OmniLight3D

var _story_ui: CanvasLayer
var _triggered := false
var _player_near := false


func _ready() -> void:
	add_to_group("voiled")
	call_deferred("_find_ui")
	if Story.voiled_seen:
		_hide_figure()
	elif not Story.mira_talked:
		# Invisible tant que Mira n'a pas parlé
		_hide_figure()


func _find_ui() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")


func _physics_process(_delta: float) -> void:
	if _triggered or Story.voiled_seen:
		return
	if not Story.mira_talked:
		return
	# Apparition quand la quête du Col commence
	if figure and not figure.visible:
		figure.visible = true
		if light:
			light.visible = true
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= TRIGGER_DIST and not _player_near:
		_player_near = true
		_trigger()


func _trigger() -> void:
	if _triggered:
		return
	_triggered = true
	if _story_ui and _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)
	if _story_ui == null or not _story_ui.has_method("start_dialogue"):
		_finish()
		return
	_story_ui.start_dialogue(
		"???",
		PackedStringArray([
			"Une silhouette voilée se dresse sur le col…",
			"« Tu as touché ce qui dormait. »",
			"« Les sceaux s'affaiblissent… et les royaumes mentent. »",
			"« Cherche les six autres. Ou laisse-les dormir. »",
			"« Nous nous reverrons, porteur du fragment. »",
			"La figure se dissout dans le brouillard…",
		]),
		_finish
	)


func _finish() -> void:
	Story.see_voiled()
	_hide_figure()
	if _story_ui:
		_story_ui.start_dialogue(
			"Narek" if Story.narek_joined else "Héros",
			PackedStringArray([
				"Il savait pour le cristal…",
				"La Vallée d'Aube n'était que le début.",
				"Quand tu seras prêt… Eldoria t'attend au-delà du col.",
			])
		)


func _hide_figure() -> void:
	if figure:
		figure.visible = false
	if light:
		light.visible = false


func get_save_data() -> Dictionary:
	return {"seen": _triggered or Story.voiled_seen}


func apply_save_data(data: Dictionary) -> void:
	_triggered = bool(data.get("seen", false)) or Story.voiled_seen
	if _triggered:
		_hide_figure()
