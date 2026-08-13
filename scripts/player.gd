extends CharacterBody3D

## Script du héros : marche, saute, regarde autour de toi.
## Souris = regard (le corps et la caméra tournent ensemble)
## ZQSD = marcher par rapport à ton regard
## Échap = libérer / reprendre la souris

const SPEED := 6.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.003
const MIN_PITCH := deg_to_rad(-60.0)
const MAX_PITCH := deg_to_rad(40.0)

@onready var camera_pivot: Node3D = $CameraPivot
@onready var anim: AnimationPlayer = $Model/Knight/AnimationPlayer

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_play_anim("Idle")


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, MIN_PITCH, MAX_PITCH)


func _physics_process(_delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * _delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()
	_update_animation()


func _update_animation() -> void:
	# Au sol : Idle si on est arrêté, sinon course
	if not is_on_floor():
		_play_anim("Jump_Idle")
		return

	var moving := Vector2(velocity.x, velocity.z).length() > 0.2
	if moving:
		_play_anim("Running_A")
	else:
		_play_anim("Idle")


func _play_anim(anim_name: String) -> void:
	if anim.current_animation == anim_name:
		return
	if anim.has_animation(anim_name):
		anim.play(anim_name)
