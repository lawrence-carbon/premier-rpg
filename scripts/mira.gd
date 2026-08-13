extends Node3D

## Mira, érudite de Boisclair — explique les Cristaux Anciens.

@export var npc_name := "Mira"

@onready var anim: AnimationPlayer = $Model/Rogue/AnimationPlayer
@onready var interact_area: Area3D = $InteractArea

var _player_near := false
var _story_ui: CanvasLayer


func _ready() -> void:
	add_to_group("mira")
	interact_area.body_entered.connect(_on_body_entered)
	interact_area.body_exited.connect(_on_body_exited)
	_play_idle()
	call_deferred("_find_story_ui")


func _find_story_ui() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")


func _unhandled_input(event: InputEvent) -> void:
	if not _player_near or not Story.can_control_player():
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
			"Le Voilé t'a trouvé… alors les sceaux s'éveillent vraiment.",
			"Garde le fragment près de toi. Eldoria aura besoin de toi.",
		]))
		return

	if Story.mira_talked:
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"Le Col de l'Aube est à l'ouest du village.",
			"Si quelqu'un surveille les cristaux… c'est par là qu'il passera.",
		]))
		return

	if not Story.crystal_found:
		_story_ui.start_dialogue(npc_name, PackedStringArray([
			"Je suis Mira. Je copie d'anciens textes près de l'église.",
			"Si tu découvres quelque chose d'étrange dans la vallée… reviens me voir.",
		]))
		return

	_story_ui.start_dialogue(
		npc_name,
		PackedStringArray([
			"Alden m'a parlé. Montre-moi ce fragment…",
			"Les textes mentionnent sept Cristaux Anciens.",
			"On croyait qu'ils donnaient de la magie. En réalité…",
			"Ils maintiennent quelque chose de prisonnier. Quelque chose d'ancien.",
			"Et depuis ton réveil du fragment, un nom revient sans cesse : le Voilé.",
			"Personne ne sait s'il veut libérer la prison… ou l'empêcher de s'ouvrir.",
			"Va au Col de l'Aube, à l'ouest. Je sens qu'il te guette déjà.",
		]),
		_on_finished
	)


func _on_finished() -> void:
	Story.finish_mira()


func _play_idle() -> void:
	if anim and anim.has_animation("Idle"):
		anim.play("Idle")
	elif anim and anim.has_animation("Unarmed_Idle"):
		anim.play("Unarmed_Idle")
