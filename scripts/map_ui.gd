extends CanvasLayer

## Radar (mini-carte) + carte complète (touche X ou clic sur le radar).

@onready var mini_button: Button = $MiniMapButton
@onready var mini_view: Control = $MiniMapButton/MiniMapView
@onready var full_root: Control = $FullMap
@onready var full_view: Control = $FullMap/Panel/Margin/VBox/Content/MapFrame/FullMapView
@onready var zoom_slider: HSlider = $FullMap/Panel/Margin/VBox/Tools/ZoomSlider
@onready var zoom_label: Label = $FullMap/Panel/Margin/VBox/Tools/ZoomLabel
@onready var close_button: Button = $FullMap/Panel/Margin/VBox/Tools/CloseButton
@onready var hint_label: Label = $MiniMapButton/Hint


func _ready() -> void:
	full_root.visible = false
	mini_button.pressed.connect(_on_mini_pressed)
	close_button.pressed.connect(close_full_map)
	zoom_slider.value_changed.connect(_on_zoom_changed)
	zoom_slider.value = 1.0
	_on_zoom_changed(1.0)
	# Radar visible seulement après l'intro
	mini_button.visible = Story.intro_done
	if not Story.intro_done:
		# L'intro peut déjà être en cours : on attend la fermeture via dialogue_closed
		# ou on poll une fois l'intro terminée
		set_process(true)
	hint_label.text = "X"


func _process(_delta: float) -> void:
	if Story.intro_done:
		mini_button.visible = true
		set_process(false)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("open_map"):
		if full_root.visible:
			close_full_map()
		else:
			open_full_map()
		get_viewport().set_input_as_handled()
	elif full_root.visible and event.is_action_pressed("ui_cancel"):
		close_full_map()
		get_viewport().set_input_as_handled()


func _on_mini_pressed() -> void:
	open_full_map()


func open_full_map() -> void:
	if full_root.visible:
		return
	# Pas pendant intro / dialogue (sauf si déjà la carte)
	if Story.ui_locked and not Story.map_open:
		return
	Story.map_open = true
	Story.lock_for_ui()
	full_root.visible = true
	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player:
		full_view.pan_world = Vector2(player.global_position.x, player.global_position.z)
		full_view.queue_redraw()


func close_full_map() -> void:
	if not full_root.visible:
		return
	full_root.visible = false
	Story.map_open = false
	Story.unlock_from_ui()


func _on_zoom_changed(value: float) -> void:
	if full_view.has_method("set_zoom"):
		full_view.set_zoom(value)
	zoom_label.text = "Zoom %.0f%%" % (value * 100.0)
