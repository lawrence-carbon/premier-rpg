extends CanvasLayer

## Interface histoire : panneau d'intro + dialogues + objectif de quête.

@onready var intro_root: Control = $Intro
@onready var intro_title: Label = $Intro/Panel/Margin/VBox/Title
@onready var intro_body: Label = $Intro/Panel/Margin/VBox/Body
@onready var intro_button: Button = $Intro/Panel/Margin/VBox/StartButton

@onready var dialogue_root: Control = $Dialogue
@onready var dialogue_name: Label = $Dialogue/Panel/Margin/VBox/Speaker
@onready var dialogue_body: Label = $Dialogue/Panel/Margin/VBox/Line
@onready var dialogue_hint: Label = $Dialogue/Panel/Margin/VBox/Hint

@onready var quest_root: Control = $QuestHud
@onready var quest_label: Label = $QuestHud/Panel/Margin/QuestLabel

@onready var prompt_root: Control = $InteractPrompt
@onready var prompt_label: Label = $InteractPrompt/Label

@onready var hp_root: Control = $HpHud
@onready var hp_label: Label = $HpHud/Panel/Margin/HpLabel

var _lines: PackedStringArray = []
var _line_index := 0
var _speaker := ""
var _on_dialogue_finished: Callable = Callable()


func _ready() -> void:
	intro_button.pressed.connect(_on_intro_start_pressed)
	Story.quest_updated.connect(_on_quest_updated)
	dialogue_root.visible = false
	quest_root.visible = false
	prompt_root.visible = false
	hp_root.visible = false
	_show_intro()


func _unhandled_input(event: InputEvent) -> void:
	if dialogue_root.visible and (
		event.is_action_pressed("interact")
		or event.is_action_pressed("ui_accept")
		or (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	):
		_advance_dialogue()
		get_viewport().set_input_as_handled()


func _show_intro() -> void:
	Story.lock_for_ui()
	intro_root.visible = true
	intro_title.text = "Les Royaumes d'Eldoria"
	intro_body.text = (
		"Tu arrives dans la Vallée d'Aube, une région paisible…\n"
		+ "enfin, elle l'était.\n\n"
		+ "À Boisclair, le village murmure : loups agressifs, "
		+ "gobelins trop organisés, routes dangereuses.\n\n"
		+ "Ton aventure commence ici."
	)


func _on_intro_start_pressed() -> void:
	intro_root.visible = false
	Story.intro_done = true
	Story.unlock_from_ui()
	hp_root.visible = true
	update_hp(8, 8)


func update_hp(current: int, maximum: int) -> void:
	if hp_root == null:
		hp_root = get_node_or_null("HpHud") as Control
	if hp_label == null:
		hp_label = get_node_or_null("HpHud/Panel/Margin/HpLabel") as Label
	if hp_root == null or hp_label == null:
		return
	hp_root.visible = true
	hp_label.text = "PV  %d / %d" % [current, maximum]


func start_dialogue(speaker: String, lines: PackedStringArray, on_finished: Callable = Callable()) -> void:
	if lines.is_empty():
		return
	_speaker = speaker
	_lines = lines
	_line_index = 0
	_on_dialogue_finished = on_finished
	Story.lock_for_ui()
	dialogue_root.visible = true
	prompt_root.visible = false
	_show_current_line()


func _show_current_line() -> void:
	dialogue_name.text = _speaker
	dialogue_body.text = _lines[_line_index]
	var last := _line_index >= _lines.size() - 1
	dialogue_hint.text = "Entrée / E / Clic — terminer" if last else "Entrée / E / Clic — continuer"


func _advance_dialogue() -> void:
	_line_index += 1
	if _line_index >= _lines.size():
		_close_dialogue()
	else:
		_show_current_line()


func _close_dialogue() -> void:
	dialogue_root.visible = false
	Story.unlock_from_ui()
	if _on_dialogue_finished.is_valid():
		_on_dialogue_finished.call()
	_on_dialogue_finished = Callable()


func show_interact_prompt(visible_now: bool, text: String = "Parler [E]") -> void:
	if Story.ui_locked:
		prompt_root.visible = false
		return
	prompt_root.visible = visible_now
	prompt_label.text = text


func _on_quest_updated(text: String) -> void:
	quest_root.visible = true
	quest_label.text = "Objectif : " + text
