extends CharacterBody3D

## Ford T : E pour monter / descendre. ZQSD pour conduire. Les roues tournent.

const MAX_SPEED := 14.0
const ACCEL := 10.0
const BRAKE := 16.0
const REVERSE_SPEED := 6.0
const STEER_SPEED := 1.35
const MAX_STEER := deg_to_rad(32.0)
const WHEEL_RADIUS := 0.16
const SEAT_OFFSET := Vector3(0.0, 0.26, 0.48)
const INTERACT_DIST := 4.2
const MOUSE_SENSITIVITY := 0.003
const MIN_PITCH := deg_to_rad(-50.0)
const MAX_PITCH := deg_to_rad(25.0)

@onready var model: Node3D = $Model
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/Camera3D
@onready var body_col: CollisionShape3D = $CollisionShape3D

var _story_ui: CanvasLayer
var _player_near := false
var _driving := false
var _steer := 0.0
var _speed := 0.0
var _front_pivots: Array[Node3D] = []
var _spin_wheels: Array[Node3D] = []
var _player_ref: CharacterBody3D
var _world_parent: Node


func _ready() -> void:
	add_to_group("vintage_car")
	camera.current = false
	call_deferred("_setup")


func _setup() -> void:
	_story_ui = get_tree().get_first_node_in_group("story_ui")
	_add_spinning_wheels()


func get_save_data() -> Dictionary:
	return {
		"x": global_position.x,
		"y": global_position.y,
		"z": global_position.z,
		"rot_y": rotation.y,
		"driving": _driving,
	}


func apply_save_data(data: Dictionary) -> void:
	if data.is_empty():
		return
	global_position = Vector3(
		float(data.get("x", global_position.x)),
		float(data.get("y", global_position.y)),
		float(data.get("z", global_position.z))
	)
	rotation.y = float(data.get("rot_y", rotation.y))
	if bool(data.get("driving", false)):
		call_deferred("_enter")


func _unhandled_input(event: InputEvent) -> void:
	if not _driving or not Story.can_control_player():
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		camera_pivot.rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clampf(camera_pivot.rotation.x, MIN_PITCH, MAX_PITCH)


func _input(event: InputEvent) -> void:
	if not Story.can_control_player():
		return
	if not event.is_action_pressed("interact"):
		return
	if _driving:
		_exit()
		get_viewport().set_input_as_handled()
		return
	if _player_near:
		_enter()
		get_viewport().set_input_as_handled()


func exit_vehicle() -> void:
	_exit()


func _physics_process(delta: float) -> void:
	if _driving:
		_drive(delta)
		_keep_player_in_seat()
		return

	var player := get_tree().get_first_node_in_group("player") as Node3D
	if player == null:
		return
	var dist := global_position.distance_to(player.global_position)
	var near_now := dist <= INTERACT_DIST and player.global_position.y > -5.0
	if near_now and not _player_near:
		_player_near = true
		_prompt("Conduire l'automobile [E]")
	elif not near_now and _player_near:
		_player_near = false
		_prompt("")


func _drive(delta: float) -> void:
	if not Story.can_control_player():
		_speed = move_toward(_speed, 0.0, BRAKE * delta)
	else:
		var throttle := Input.get_axis("move_back", "move_forward")
		if throttle > 0.1:
			_speed = move_toward(_speed, MAX_SPEED, ACCEL * delta)
		elif throttle < -0.1:
			_speed = move_toward(_speed, -REVERSE_SPEED, BRAKE * delta)
		else:
			_speed = move_toward(_speed, 0.0, BRAKE * 0.45 * delta)

		var steer_input := Input.get_axis("move_right", "move_left")
		var steer_target := steer_input * MAX_STEER
		# Moins de braquage à grande vitesse
		var speed_factor := 1.0 - clampf(absf(_speed) / MAX_SPEED, 0.0, 0.7) * 0.55
		steer_target *= speed_factor
		_steer = move_toward(_steer, steer_target, STEER_SPEED * delta)
		if absf(_speed) > 0.4:
			rotation.y += _steer * signf(_speed) * delta * 1.8

	if not is_on_floor():
		velocity += get_gravity() * delta
	var forward := -global_transform.basis.z
	velocity.x = forward.x * _speed
	velocity.z = forward.z * _speed
	move_and_slide()

	_animate_wheels(delta)
	_prompt("Descendre [E]  —  ZQSD pour conduire")


func _animate_wheels(delta: float) -> void:
	var spin := (_speed / maxf(WHEEL_RADIUS, 0.05)) * delta
	for w in _spin_wheels:
		if is_instance_valid(w):
			w.rotate_y(-spin)
	for p in _front_pivots:
		if is_instance_valid(p):
			p.rotation.y = _steer


func _keep_player_in_seat() -> void:
	if _player_ref == null:
		return
	_player_ref.global_position = global_transform * SEAT_OFFSET
	_player_ref.velocity = Vector3.ZERO
	_player_ref.rotation.y = rotation.y


func _enter() -> void:
	var player := get_tree().get_first_node_in_group("player") as CharacterBody3D
	if player == null or _driving:
		return
	_player_ref = player
	_world_parent = player.get_parent()
	_driving = true
	Story.in_vehicle = true
	_player_near = false
	if has_node("Label"):
		$Label.visible = false
	if player.has_method("set_driving"):
		player.set_driving(true)
	camera.current = true
	camera_pivot.rotation = Vector3.ZERO
	_prompt("Descendre [E]  —  ZQSD pour conduire")


func _exit() -> void:
	if not _driving:
		return
	_driving = false
	Story.in_vehicle = false
	_speed = 0.0
	_steer = 0.0
	velocity = Vector3.ZERO
	camera.current = false
	if _player_ref:
		var side := global_transform.basis.x * 2.2
		_player_ref.global_position = global_position + side + Vector3(0, 0.2, 0)
		_player_ref.velocity = Vector3.ZERO
		if _player_ref.has_method("set_driving"):
			_player_ref.set_driving(false)
	_player_ref = null
	if has_node("Label"):
		$Label.visible = true
	_prompt("")


func _prompt(text: String) -> void:
	if _story_ui and _story_ui.has_method("show_interact_prompt"):
		_story_ui.show_interact_prompt(text != "", text)


## Le modèle 3D est d'une seule pièce : on n'y touche pas.
## On ajoute 4 roues simples qui tournent par-dessus (sinon la carrosserie se tord).
func _add_spinning_wheels() -> void:
	var hubs := [
		Vector3(-0.50, -0.12, -0.21), # arrière gauche
		Vector3(-0.50, -0.12, 0.21),  # arrière droit
		Vector3(0.42, -0.12, -0.21),  # avant gauche
		Vector3(0.42, -0.12, 0.21),   # avant droit
	]
	var tire_mat := StandardMaterial3D.new()
	tire_mat.albedo_color = Color(0.08, 0.08, 0.08)
	tire_mat.roughness = 0.9
	var hub_mat := StandardMaterial3D.new()
	hub_mat.albedo_color = Color(0.55, 0.32, 0.12)
	hub_mat.roughness = 0.8

	var tire_mesh := CylinderMesh.new()
	tire_mesh.top_radius = 0.16
	tire_mesh.bottom_radius = 0.16
	tire_mesh.height = 0.09
	tire_mesh.radial_segments = 12

	var hub_mesh := CylinderMesh.new()
	hub_mesh.top_radius = 0.06
	hub_mesh.bottom_radius = 0.06
	hub_mesh.height = 0.1
	hub_mesh.radial_segments = 8

	for w in 4:
		var holder := Node3D.new()
		holder.position = hubs[w]
		model.add_child(holder)
		var axle := Node3D.new()
		axle.rotation_degrees.x = 90.0
		holder.add_child(axle)
		var spinner := Node3D.new()
		axle.add_child(spinner)
		var tire := MeshInstance3D.new()
		tire.mesh = tire_mesh
		tire.material_override = tire_mat
		spinner.add_child(tire)
		var hub := MeshInstance3D.new()
		hub.mesh = hub_mesh
		hub.material_override = hub_mat
		spinner.add_child(hub)
		_spin_wheels.append(spinner)
		if w >= 2:
			_front_pivots.append(holder)
