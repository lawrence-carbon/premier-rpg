extends CharacterBody3D

## Héros joueur : déplacement, caméra, attaque (F), points de vie.

const SPEED := 6.0
const JUMP_VELOCITY := 4.5
const MOUSE_SENSITIVITY := 0.003
const MIN_PITCH := deg_to_rad(-60.0)
const MAX_PITCH := deg_to_rad(40.0)
const ATTACK_RANGE := 2.4
const ATTACK_COOLDOWN := 0.45
const MAX_HP := 8

@onready var camera_pivot: Node3D = $CameraPivot
@onready var anim: AnimationPlayer = $Model/Knight/AnimationPlayer

var hp := MAX_HP
var _attack_cd := 0.0


func _ready() -> void:
	add_to_group("player")
	hp = MAX_HP
	if Story.can_control_player():
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	_play_anim("Idle")
	call_deferred("_emit_hp")


func _unhandled_input(event: InputEvent) -> void:
	if not Story.can_control_player():
		return

	if event.is_action_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return

	if event.is_action_pressed("attack"):
		_try_attack()
		get_viewport().set_input_as_handled()
		return

	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * MOUSE_SENSITIVITY)
		camera_pivot.rotate_x(-event.relative.y * MOUSE_SENSITIVITY)
		camera_pivot.rotation.x = clamp(camera_pivot.rotation.x, MIN_PITCH, MAX_PITCH)


func _physics_process(_delta: float) -> void:
	_attack_cd = maxf(_attack_cd - _delta, 0.0)

	if not Story.can_control_player():
		velocity.x = 0.0
		velocity.z = 0.0
		if not is_on_floor():
			velocity += get_gravity() * _delta
		move_and_slide()
		_play_anim("Idle")
		return

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


func take_damage(amount: int) -> void:
	hp = maxi(hp - amount, 0)
	_emit_hp()
	if hp <= 0:
		_respawn()


func _try_attack() -> void:
	if _attack_cd > 0.0:
		return
	_attack_cd = ATTACK_COOLDOWN
	_play_anim("1H_Melee_Attack_Slice_Horizontal")
	var origin := global_position + Vector3(0, 0.9, 0)
	var forward := -global_transform.basis.z
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if enemy == null or not is_instance_valid(enemy):
			continue
		var to_enemy: Vector3 = enemy.global_position - origin
		to_enemy.y = 0.0
		if to_enemy.length() > ATTACK_RANGE:
			continue
		# Doit être plutôt devant toi
		if forward.dot(to_enemy.normalized()) < 0.15:
			continue
		if enemy.has_method("take_damage"):
			enemy.take_damage(1)


func _respawn() -> void:
	# Retour près du village, PV restaurés
	global_position = Vector3(0, 0.2, 6)
	hp = MAX_HP
	_emit_hp()
	var ui := get_tree().get_first_node_in_group("story_ui")
	if ui and ui.has_method("start_dialogue"):
		ui.start_dialogue("Héros", PackedStringArray([
			"Tu t'es évanoui… Tu te réveilles près de Boisclair.",
		]))


func _emit_hp() -> void:
	var ui := get_tree().get_first_node_in_group("story_ui")
	if ui and ui.has_method("update_hp"):
		ui.update_hp(hp, MAX_HP)


func _update_animation() -> void:
	if _attack_cd > 0.15:
		return
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
