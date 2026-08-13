extends CanvasLayer

## Menu pause : sauvegarder, charger, nouvelle partie.

@onready var root: Control = $Root
@onready var title: Label = $Root/Panel/Margin/VBox/Title
@onready var status_label: Label = $Root/Panel/Margin/VBox/Status
@onready var btn_continue: Button = $Root/Panel/Margin/VBox/BtnContinue
@onready var btn_save: Button = $Root/Panel/Margin/VBox/BtnSave
@onready var btn_load: Button = $Root/Panel/Margin/VBox/BtnLoad
@onready var btn_new: Button = $Root/Panel/Margin/VBox/BtnNew
@onready var btn_quit: Button = $Root/Panel/Margin/VBox/BtnQuit


func _ready() -> void:
	layer = 30
	root.visible = false
	btn_continue.pressed.connect(close_menu)
	btn_save.pressed.connect(_on_save)
	btn_load.pressed.connect(_on_load)
	btn_new.pressed.connect(_on_new)
	btn_quit.pressed.connect(_on_quit)
	_refresh_buttons()


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return

	# Pendant dialogue / intro histoire : ne pas ouvrir le menu
	var story_ui := get_tree().get_first_node_in_group("story_ui")
	if story_ui:
		var intro_vis: bool = story_ui.get("intro_root") != null and story_ui.intro_root.visible
		var dial_vis: bool = story_ui.get("dialogue_root") != null and story_ui.dialogue_root.visible
		if intro_vis or dial_vis:
			return

	# Si la carte est ouverte, elle gère Échap en premier (layer plus bas) :
	# ici on ouvre le menu seulement si la carte est fermée.
	if Story.map_open and not Story.menu_open:
		return

	if Story.menu_open:
		close_menu()
	elif Story.intro_done:
		open_menu()
	get_viewport().set_input_as_handled()


func open_menu() -> void:
	# Ferme la carte si elle est ouverte
	var map_ui := get_node_or_null("../MapUI")
	if map_ui and map_ui.has_method("close_full_map") and Story.map_open:
		map_ui.close_full_map()
	Story.menu_open = true
	Story.lock_for_ui()
	root.visible = true
	_refresh_buttons()
	status_label.text = ""


func close_menu() -> void:
	if not Story.menu_open:
		return
	root.visible = false
	Story.menu_open = false
	Story.unlock_from_ui()


func _refresh_buttons() -> void:
	btn_load.disabled = not SaveGame.has_save()
	btn_save.disabled = not Story.intro_done


func _on_save() -> void:
	if SaveGame.save_game():
		status_label.text = "Partie sauvegardée !"
		_refresh_buttons()
	else:
		status_label.text = "Erreur de sauvegarde."


func _on_load() -> void:
	if not SaveGame.has_save():
		status_label.text = "Aucune sauvegarde."
		return
	status_label.text = "Chargement…"
	close_menu()
	await get_tree().process_frame
	if SaveGame.load_game():
		var ui := get_tree().get_first_node_in_group("story_ui")
		if ui and ui.has_method("hide_intro_for_continue"):
			ui.hide_intro_for_continue()
	else:
		open_menu()
		status_label.text = "Impossible de charger."


func _on_new() -> void:
	status_label.text = "Nouvelle partie…"
	Story.menu_open = false
	root.visible = false
	SaveGame.new_game()


func _on_quit() -> void:
	get_tree().quit()
