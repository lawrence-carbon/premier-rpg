extends Control

## Dessine une carte 2D (radar ou carte complète) à partir des positions 3D.
## Nord = haut de l'écran (= -Z dans le monde).

@export var centered_on_player := true
@export var view_radius := 70.0 ## Unités monde visibles (mode radar)
@export var show_labels := false
@export var show_compass := true
@export var show_legend_hint := false
@export var zoom := 1.0
@export var interactive := false

var pan_world := Vector2.ZERO ## Décalage du centre (mode carte pleine)
var _player: Node3D
var _dragging := false
var _drag_last := Vector2.ZERO


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP if interactive else Control.MOUSE_FILTER_IGNORE
	_find_player()


func _process(_delta: float) -> void:
	if _player == null:
		_find_player()
	queue_redraw()


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as Node3D


func set_zoom(value: float) -> void:
	zoom = clampf(value, 0.45, 3.5)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:
			set_zoom(zoom * 1.12)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:
			set_zoom(zoom / 1.12)
			accept_event()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			_dragging = event.pressed
			_drag_last = event.position
			accept_event()
	elif event is InputEventMouseMotion and _dragging:
		var center := size * 0.5
		var scale_px := _pixels_per_unit()
		var delta: Vector2 = event.position - _drag_last
		_drag_last = event.position
		# Déplacer la carte (inverse du drag)
		pan_world.x -= delta.x / scale_px
		pan_world.y -= delta.y / scale_px
		accept_event()


func _pixels_per_unit() -> float:
	var radius_px := minf(size.x, size.y) * 0.5 - 8.0
	if centered_on_player:
		return radius_px / maxf(view_radius / zoom, 1.0)
	return radius_px / maxf(WorldMap.WORLD_HALF / zoom, 1.0)


func _map_center_world() -> Vector2:
	if centered_on_player and _player:
		return Vector2(_player.global_position.x, _player.global_position.z) + pan_world
	return pan_world


func world_to_map(world_xz: Vector2) -> Vector2:
	var center := size * 0.5
	var scale_px := _pixels_per_unit()
	var c := _map_center_world()
	# Nord (-Z) vers le haut → inverser Z
	var local := Vector2(world_xz.x - c.x, world_xz.y - c.y)
	return center + Vector2(local.x, local.y) * scale_px


func _draw() -> void:
	var rect := Rect2(Vector2.ZERO, size)
	# Fond
	draw_rect(rect, Color(0.12, 0.18, 0.14, 0.92))
	# Grille légère
	_draw_grid()
	# Zones POI
	for poi in WorldMap.POIS:
		_draw_poi(poi)
	# Joueur
	if _player:
		_draw_player()
	# Cadre + rose des vents
	draw_rect(rect, Color(0.75, 0.82, 0.7, 0.9), false, 2.0)
	if show_compass:
		_draw_compass()


func _draw_grid() -> void:
	var step := 20.0
	var c := _map_center_world()
	var color := Color(1, 1, 1, 0.07)
	var half := WorldMap.WORLD_HALF
	var x0 := floorf((c.x - half) / step) * step
	var z0 := floorf((c.y - half) / step) * step
	var x := x0
	while x <= c.x + half:
		var a := world_to_map(Vector2(x, c.y - half))
		var b := world_to_map(Vector2(x, c.y + half))
		draw_line(a, b, color, 1.0)
		x += step
	var z := z0
	while z <= c.y + half:
		var a2 := world_to_map(Vector2(c.x - half, z))
		var b2 := world_to_map(Vector2(c.x + half, z))
		draw_line(a2, b2, color, 1.0)
		z += step
	# Bord du monde
	var corners := [
		world_to_map(Vector2(-half, -half)),
		world_to_map(Vector2(half, -half)),
		world_to_map(Vector2(half, half)),
		world_to_map(Vector2(-half, half)),
		world_to_map(Vector2(-half, -half)),
	]
	for i in 4:
		draw_line(corners[i], corners[i + 1], Color(0.5, 0.6, 0.45, 0.35), 1.5)


func _draw_poi(poi: Dictionary) -> void:
	var pos: Vector2 = poi["pos"]
	var radius: float = float(poi.get("radius", 12.0))
	var col: Color = WorldMap.color_for_type(str(poi["type"]))
	var center := world_to_map(pos)
	var scale_px := _pixels_per_unit()
	var r_px := maxf(radius * scale_px, 4.0)
	var fill := Color(col, 0.35)
	var edge := Color(col, 0.85)
	draw_circle(center, r_px, fill)
	draw_arc(center, r_px, 0.0, TAU, 32, edge, 2.0)
	# Marqueur de quête
	var show_star := false
	if poi.get("quest", false) and Story.quest_active:
		var id := str(poi.get("id", ""))
		if id == "camp_grak":
			show_star = Story.stage == "narek"
		elif id == "foret_emeraude":
			show_star = Story.stage == "forest" or Story.stage == "none"
		elif id == "crypt":
			show_star = Story.stage == "grak_done" or Story.stage == "crypt"
		elif id == "boisclair":
			show_star = Story.stage == "crystal_done"
		elif id == "mira":
			show_star = Story.stage == "mira"
		elif id == "col_aube":
			show_star = Story.stage == "col"
		else:
			show_star = true
	if show_star:
		draw_circle(center, 5.0, Color(1.0, 0.85, 0.2))
		draw_circle(center, 5.0, Color(0.2, 0.15, 0.0), false, 1.5)
	if show_labels:
		var font := ThemeDB.fallback_font
		var fs := 14 if not centered_on_player else 11
		draw_string(font, center + Vector2(8, -6), str(poi["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.95, 0.95, 0.9))


func _draw_player() -> void:
	var p := world_to_map(Vector2(_player.global_position.x, _player.global_position.z))
	# Triangle orienté selon le regard (rot_y=0 → Nord = haut)
	var yaw := _player.global_rotation.y
	var ang := -yaw - PI * 0.5
	var tip := Vector2(cos(ang), sin(ang)) * 10.0
	var left := Vector2(cos(ang + 2.4), sin(ang + 2.4)) * 7.0
	var right := Vector2(cos(ang - 2.4), sin(ang - 2.4)) * 7.0
	var pts := PackedVector2Array([p + tip, p + left, p + right])
	draw_colored_polygon(pts, Color(0.25, 0.55, 1.0))
	draw_polyline(PackedVector2Array([pts[0], pts[1], pts[2], pts[0]]), Color(0.9, 0.95, 1.0), 1.5, true)


func _draw_compass() -> void:
	var font := ThemeDB.fallback_font
	var pad := 10.0
	var n := Vector2(size.x * 0.5, pad)
	var s := Vector2(size.x * 0.5, size.y - pad - 4.0)
	var e := Vector2(size.x - pad - 4.0, size.y * 0.5)
	var w := Vector2(pad, size.y * 0.5)
	draw_string(font, n + Vector2(-5, 10), "N", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(1, 0.85, 0.4))
	draw_string(font, s + Vector2(-4, 0), "S", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.85, 0.8))
	draw_string(font, e + Vector2(-10, 4), "E", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.85, 0.8))
	draw_string(font, w + Vector2(0, 4), "O", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.8, 0.85, 0.8))
