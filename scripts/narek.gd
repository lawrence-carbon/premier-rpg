extends Node3D

## Narek, le rôdeur : à aider dans la Forêt d'Émeraude, puis compagnon.

@export var npc_name := "Narek"

@onready var anim: AnimationPlayer = $Model/Rogue/AnimationPlayer
@onready var interact_area: Area3D = $InteractArea

var _player_near := false
var _rescued := false
var _following := false
var _story_ui: CanvasLayer
var _player: Node3D

## Assez loin pour ne pas bloquer les interactions (E) devant le héros
const FOLLOW_DISTANCE := 5.0
const FOLLOW_SPEED := 5.5
const FOLLOW_SIDE := 1.4


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_play_anim("Idle")
	add_to_group("narek")
	call_deferred("_find_refs")
	Story.companion_changed.connect(_on_companion_changed)


func get_save_data() -> Dictionary:
	return {
		"x": global_position.x,
		"y": global_position.y,
		"z": global_position.z,
		"rescued": _rescued,
		"following": _following,
	}


func apply_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	global_position = Vector3(
		float(data.get("x", global_position.x)),
		float(data.get("y", 0.0)),
		float(data.get("z", global_position.z))
	)
	_rescued = bool(data.get("rescued", false)) or Story.narek_joined
	_following = bool(data.get("following", false)) or Story.narek_joined
	if _following:
		Story.narek_joined = true
		call_deferred("_disable_companion_interact")


func _find_refs() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")
	_player = get_tree().get_first_node_in_group("player")
	if _following:
		_disable_companion_interact()


func _unhandled_input(event: InputEvent) -> void:
	if not Story.can_control_player():
		return
	# T = parler au compagnon (même s'il suit)
	if _following and event.is_action_pressed("talk_companion"):
		_talk_as_companion()
		get_viewport().set_input_as_handled()
		return
	# E = parler seulement avant qu'il ne te suive
	if _following:
		return
	if not _player_near:
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

	var follow := _player as Node3D
	var dist_hold := FOLLOW_DISTANCE
	var speed := FOLLOW_SPEED
	if Story.in_vehicle:
		var car := get_tree().get_first_node_in_group("vintage_car") as Node3D
		if car:
			follow = car
			dist_hold = 8.0
			speed = 12.0

	# Point d'attente : derrière et un peu sur le côté
	var back := -follow.global_transform.basis.z
	back.y = 0.0
	if back.length_squared() < 0.01:
		back = Vector3(0, 0, 1)
	else:
		back = back.normalized()
	var side := follow.global_transform.basis.x
	side.y = 0.0
	side = side.normalized()
	var hold := follow.global_position - back * dist_hold + side * FOLLOW_SIDE
	hold.y = follow.global_position.y

	var to_hold := hold - global_position
	to_hold.y = 0.0
	var dist := to_hold.length()
	if dist > 0.35:
		var step := minf(speed * delta, dist)
		global_position += to_hold.normalized() * step
		global_position.y = hold.y
		look_at(Vector3(follow.global_position.x, global_position.y, follow.global_position.z), Vector3.UP)
		_play_anim("Running_A")
	else:
		_play_anim("Idle")


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_player_near = true
	if _following:
		return
	if _story_ui and _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(true, "Parler à %s [E]" % npc_name)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false
		if _following:
			return
		if _story_ui and _story_ui.has_method("show_interact_prompt"):
			_story_ui.show_interact_prompt(false)


func _disable_companion_interact() -> void:
	_player_near = false
	if interact_area:
		interact_area.monitoring = false
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


func _talk_as_companion() -> void:
	if _story_ui == null or not _story_ui.has_method("start_dialogue"):
		return
	if Story.voiled_seen:
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"Le Voilé… il savait pour le cristal.",
			"Quand tu voudras quitter la vallée, je serai à tes côtés.",
		]))
	elif Story.mira_talked:
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"Le Col de l'Aube est à l'ouest. Mira a raison : quelqu'un nous guette.",
		]))
	elif Story.crystal_found:
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"Ce fragment… Alden et Mira doivent en entendre parler.",
			"Retournons à Boisclair.",
		]))
	elif Story.has_key or Story.stage == "grak_done":
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"La clé de Grak ouvre quelque chose près de la colline, au nord.",
			"Allons-y.",
		]))
	else:
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"Le camp de Grak est plus à l'est.",
			"Je reste juste derrière. Appuie sur N si tu veux me parler.",
		]))


func _on_rescue_finished() -> void:
	_rescued = true
	Story.set_stage("narek")
	Story.join_narek()
	Story.set_quest("Suivre Narek : trouver le camp de Grak (plus à l'est)")
	_following = true
	_disable_companion_interact()


func _on_companion_changed(active: bool) -> void:
	_following = active and _rescued
	if _following:
		_disable_companion_interact()
	elif interact_area:
		interact_area.monitoring = true


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
