extends Node3D

## Narek, le rôdeur : à aider dans la Forêt d'Émeraude, puis compagnon.

@export var npc_name := "Narek"

@onready var anim: AnimationPlayer = $Model/RogueHooded/AnimationPlayer
@onready var interact_area: Area3D = $InteractArea

var _player_near := false
var _rescued := false
var _following := false
var _story_ui: CanvasLayer
var _player: Node3D

const FOLLOW_DISTANCE := 2.8
const FOLLOW_SPEED := 5.0


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_play_anim("Idle")
	call_deferred("_find_refs")
	Story.companion_changed.connect(_on_companion_changed)


func _find_refs() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")
	_player = get_tree().get_first_node_in_group("player")


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or not Story.can_control_player():
		return
	if event.is_action_pressed("interact"):
		_talk()
		get_viewport().set_input_as_handled()


func _physics_process(delta: float) -> void:
	if not _following or _player == null:
		return
	if not Story.can_control_player():
		_play_anim("Idle")
		return

	var target := _player.global_position
	var to_player := target - global_position
	to_player.y = 0.0
	var dist := to_player.length()
	if dist > FOLLOW_DISTANCE:
		var step := minf(FOLLOW_SPEED * delta, dist - FOLLOW_DISTANCE + 0.05)
		global_position += to_player.normalized() * step
		global_position.y = 0.0
		look_at(Vector3(target.x, global_position.y, target.z), Vector3.UP)
		_play_anim("Running_A")
	else:
		_play_anim("Idle")


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = true
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(true, "Parler à %s [E]" % npc_name)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(false)


func _nearby_goblins_alive() -> bool:
	for g in get_tree().get_nodes_in_group("goblins"):
		if g == null or not is_instance_valid(g):
			continue
		if global_position.distance_to(g.global_position) < 18.0:
			return true
	return false


func _talk() -> void:
	if _story_ui == null or not _story_ui.has_method("start_dialogue"):
		return
	if _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)

	if _nearby_goblins_alive():
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"Ces gobelins… aide-moi à les écarter !",
			"(Approche-toi et appuie sur F pour attaquer)",
		]))
		return

	if _rescued:
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"Le camp de Grak est plus à l'est, au fond de la forêt.",
			"Reste sur tes gardes. Ils obéissent à quelqu'un…",
		]))
		return

	_story_ui.start_dialogue(
		npc_name,
		PackedStringArray([
			"Merci, voyageur. Je m'appelle Narek.",
			"Ces gobelins ne sont pas comme d'habitude…",
			"Ils suivent des ordres. C'est trop organisé.",
			"Ils transportent des objets vers un camp plus profond dans la forêt.",
			"Si tu veux comprendre ce qui se passe, je t'accompagne.",
		]),
		_on_rescue_finished
	)


func _on_rescue_finished() -> void:
	_rescued = true
	Story.set_stage("narek")
	Story.join_narek()
	Story.set_quest("Suivre Narek : trouver le camp de Grak (plus à l'est)")
	_following = true


func _on_companion_changed(active: bool) -> void:
	_following = active and _rescued


func _play_anim(anim_name: String) -> void:
	if anim == null:
		return
	if anim.current_animation == anim_name:
		return
	if anim.has_animation(anim_name):
		anim.play(anim_name)
	elif anim_name == "Running_A" and anim.has_animation("Walking_A"):
		anim.play("Walking_A")
	elif anim.has_animation("Idle"):
		anim.play("Idle")
