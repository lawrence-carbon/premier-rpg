extends Node3D

## Villageois de Boisclair : donne la première mission, puis la suite après le cristal.

@export var npc_name := "Alden"
@export var interact_radius := 2.8

@onready var anim: AnimationPlayer = $Model/Rogue/AnimationPlayer
@onready var interact_area: Area3D = $InteractArea

var _player_near := false
var _already_gave_quest := false
var _story_ui: CanvasLayer


func _ready() -> void:
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_play_idle()
	add_to_group("alden")
	call_deferred("_find_story_ui")


func get_save_data() -> Dictionary:
	return {"gave_quest": _already_gave_quest}


func apply_save_data(data: Dictionary) -> void:
	_already_gave_quest = bool(data.get("gave_quest", false))


func _find_story_ui() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")
	if _story_ui == null:
		_story_ui = get_node_or_null("../StoryUI")


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near:
		return
	if not Story.can_control_player():
		return
	if event.is_action_pressed("interact"):
		_talk()
		get_viewport().set_input_as_handled()


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


func _talk() -> void:
	if _story_ui == null or not _story_ui.has_method("start_dialogue"):
		return
	if _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(false)

	if Story.voiled_seen:
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"Tu as vu le Voilé… Boisclair ne t'oubliera pas.",
			"Quand tu quitteras la vallée, emporte notre gratitude avec toi.",
		]))
		return

	if Story.mira_talked:
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"Mira a raison. Le Col de l'Aube est à l'ouest.",
			"Fais attention… le brouillard y est étrange depuis des jours.",
		]))
		return

	if Story.crystal_found:
		_story_ui.start_dialogue(
			npc_name,
			PackedStringArray([
				"Tu es de retour… et tu portes quelque chose d'ancien.",
				"Ce fragment… Mira, devant l'église, copie des textes sur les cristaux.",
				"Montre-lui ça. Elle en saura plus que moi.",
				"La vallée n'était qu'un début, n'est-ce pas ?",
			]),
			_on_crystal_return
		)
		return

	if _already_gave_quest:
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"La Forêt d'Émeraude est à l'est du village.",
			"Fais attention… les gobelins n'agissent plus comme avant.",
		]))
		return

	_story_ui.start_dialogue(
		npc_name,
		PackedStringArray([
			"Bienvenue à Boisclair, voyageur.",
			"Depuis quelque temps, la vallée a changé.",
			"Les loups attaquent les routes… et les gobelins se rassemblent.",
			"Ils cherchent quelque chose dans la Forêt d'Émeraude.",
			"Peux-tu aller enquêter là-bas ? Nous avons besoin d'aide.",
		]),
		_on_first_talk_finished
	)


func _on_first_talk_finished() -> void:
	_already_gave_quest = true
	Story.set_stage("forest")
	Story.set_quest("Enquêter dans la Forêt d'Émeraude (à l'est)")


func _on_crystal_return() -> void:
	_already_gave_quest = true
	Story.send_to_mira()


func _play_idle() -> void:
	if anim and anim.has_animation("Idle"):
		anim.play("Idle")
	elif anim and anim.has_animation("Unarmed_Idle"):
		anim.play("Unarmed_Idle")
