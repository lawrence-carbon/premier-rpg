extends CharacterBody3D

## Petit gobelin stylisé : poursuit le joueur, meurt en 2 coups (touche F).

const SPEED := 3.2
const ATTACK_RANGE := 1.6
const ATTACK_COOLDOWN := 1.2
const DAMAGE := 1

@export var max_hp := 2
@export var aggro_range := 12.0

var hp := 2
var _cooldown := 0.0
var _dead := false
var _player: Node3D
var _flash_mat: StandardMaterial3D

@onready var model: Node3D = $Model
@onready var anim_flash: Timer = $FlashTimer


func _ready() -> void:
	hp = max_hp
	add_to_group("enemies")
	add_to_group("goblins")
	_player = get_tree().get_first_node_in_group("player")
	anim_flash.timeout.connect(_on_flash_timeout)
	_flash_mat = StandardMaterial3D.new()
	_flash_mat.albedo_color = Color(1.0, 0.35, 0.25)


func _physics_process(delta: float) -> void:
	if _dead or not Story.can_control_player():
		velocity.x = 0.0
		velocity.z = 0.0
		move_and_slide()
		return

	if _player == null:
		_player = get_tree().get_first_node_in_group("player")
		return

	_cooldown = maxf(_cooldown - delta, 0.0)

	if not is_on_floor():
		velocity += get_gravity() * delta

	var to_player := _player.global_position - global_position
	to_player.y = 0.0
	var dist := to_player.length()

	if dist < aggro_range and dist > 0.1:
		var dir := to_player.normalized()
		velocity.x = dir.x * SPEED
		velocity.z = dir.z * SPEED
		# Regarde le joueur sans se pencher
		var look_pos := Vector3(_player.global_position.x, global_position.y, _player.global_position.z)
		if look_pos.distance_to(global_position) > 0.05:
			look_at(look_pos, Vector3.UP)
		if dist <= ATTACK_RANGE and _cooldown <= 0.0:
			_hit_player()
			_cooldown = ATTACK_COOLDOWN
	else:
		velocity.x = move_toward(velocity.x, 0.0, SPEED)
		velocity.z = move_toward(velocity.z, 0.0, SPEED)

	move_and_slide()


func take_damage(amount: int) -> void:
	if _dead:
		return
	hp -= amount
	_flash()
	if hp <= 0:
		_die()


func _hit_player() -> void:
	if _player and _player.has_method("take_damage"):
		_player.take_damage(DAMAGE)


func _flash() -> void:
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = _flash_mat
	anim_flash.start(0.12)


func _on_flash_timeout() -> void:
	if _dead:
		return
	for mesh in model.find_children("*", "MeshInstance3D", true, false):
		mesh.material_override = null


func _die() -> void:
	_dead = true
	remove_from_group("goblins")
	await get_tree().create_timer(0.15).timeout
	queue_free()
