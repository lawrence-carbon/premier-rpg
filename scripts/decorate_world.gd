extends Node3D

## Place le décor du monde (village, forêt, collines…).
## Les modèles viennent du pack KayKit Medieval (même style que le héros).

const PROP_SCALE := 6.0
const MAP_HALF := 180.0 # le sol va de -180 à +180

@onready var decor: Node3D = $Decor


func _ready() -> void:
	_build_village()
	_build_forest(Vector3(55, 0, -40), 45, 70)
	_build_forest(Vector3(-70, 0, 50), 40, 55)
	_build_forest(Vector3(90, 0, 70), 35, 40)
	_build_hills()
	_build_rocks()
	_build_mountains()


func _spawn(path: String, pos: Vector3, yaw_deg: float = 0.0, scale_mul: float = 1.0) -> Node3D:
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("Impossible de charger: " + path)
		return null
	var node: Node3D = packed.instantiate()
	node.position = pos
	node.rotation_degrees.y = yaw_deg
	node.scale = Vector3.ONE * (PROP_SCALE * scale_mul)
	decor.add_child(node)
	_add_collisions(node)
	return node


func _add_collisions(root: Node) -> void:
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		# Collision solide pour que le héros ne traverse pas
		mesh.create_trimesh_collision()


func _build_village() -> void:
	# Village en bois près du point de départ
	var base := Vector3(-18, 0, -22)
	_spawn("res://assets/environment/buildings/building_home_A_yellow.gltf", base + Vector3(0, 0, 0), 20)
	_spawn("res://assets/environment/buildings/building_home_B_yellow.gltf", base + Vector3(10, 0, 4), -30)
	_spawn("res://assets/environment/buildings/building_home_A_yellow.gltf", base + Vector3(-8, 0, 8), 140)
	_spawn("res://assets/environment/buildings/building_tavern_yellow.gltf", base + Vector3(4, 0, -10), 10)
	_spawn("res://assets/environment/buildings/building_well_yellow.gltf", base + Vector3(2, 0, 2), 0, 0.7)
	_spawn("res://assets/environment/buildings/building_blacksmith_yellow.gltf", base + Vector3(-12, 0, -6), 50)
	_spawn("res://assets/environment/buildings/building_market_yellow.gltf", base + Vector3(14, 0, -4), -15)
	_spawn("res://assets/environment/buildings/building_church_yellow.gltf", base + Vector3(-4, 0, -18), 5)
	_spawn("res://assets/environment/buildings/building_lumbermill_yellow.gltf", base + Vector3(18, 0, 10), -40)
	_spawn("res://assets/environment/buildings/building_windmill_yellow.gltf", base + Vector3(-20, 0, 12), 25)
	# Quelques arbres près du village
	for i in 8:
		var a := float(i) * 0.9
		_spawn(
			"res://assets/environment/nature/tree_single_A.gltf",
			base + Vector3(cos(a) * 22.0, 0, sin(a) * 18.0),
			i * 40.0,
			0.9 + (i % 3) * 0.15
		)


func _build_forest(center: Vector3, radius: float, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(center.x * 1000 + center.z))
	var tree_paths := [
		"res://assets/environment/nature/tree_single_A.gltf",
		"res://assets/environment/nature/tree_single_B.gltf",
		"res://assets/environment/nature/trees_A_small.gltf",
		"res://assets/environment/nature/trees_A_medium.gltf",
		"res://assets/environment/nature/trees_B_small.gltf",
		"res://assets/environment/nature/trees_B_medium.gltf",
	]
	for i in count:
		var angle := rng.randf() * TAU
		var dist := rng.randf() * radius
		var pos := center + Vector3(cos(angle) * dist, 0, sin(angle) * dist)
		# Évite le centre du village
		if Vector2(pos.x + 18, pos.z + 22).length() < 28.0:
			continue
		var path: String = tree_paths[rng.randi() % tree_paths.size()]
		_spawn(path, pos, rng.randf() * 360.0, rng.randf_range(0.85, 1.35))
	# Bouquets d'arbres prêts à l'emploi
	_spawn("res://assets/environment/nature/trees_A_large.gltf", center + Vector3(8, 0, -6), 15, 1.1)
	_spawn("res://assets/environment/nature/trees_B_large.gltf", center + Vector3(-10, 0, 8), -40, 1.0)


func _build_hills() -> void:
	_spawn("res://assets/environment/nature/hills_A_trees.gltf", Vector3(40, 0, -70), 0, 1.2)
	_spawn("res://assets/environment/nature/hills_B_trees.gltf", Vector3(-50, 0, -80), 45, 1.3)
	_spawn("res://assets/environment/nature/hills_C_trees.gltf", Vector3(70, 0, 30), -20, 1.2)
	_spawn("res://assets/environment/nature/hills_A.gltf", Vector3(-30, 0, 90), 90, 1.4)
	_spawn("res://assets/environment/nature/hills_B.gltf", Vector3(100, 0, -20), 10, 1.3)
	_spawn("res://assets/environment/nature/hill_single_A.gltf", Vector3(15, 0, 35), 0, 1.5)
	_spawn("res://assets/environment/nature/hill_single_B.gltf", Vector3(-40, 0, 20), 60, 1.6)
	_spawn("res://assets/environment/nature/hill_single_C.gltf", Vector3(25, 0, -50), -30, 1.4)


func _build_mountains() -> void:
	# Collines / montagnes au loin pour fermer le paysage
	_spawn("res://assets/environment/nature/mountain_A_grass_trees.gltf", Vector3(-120, 0, -120), 20, 2.0)
	_spawn("res://assets/environment/nature/mountain_B_grass.gltf", Vector3(130, 0, -110), -15, 2.2)
	_spawn("res://assets/environment/nature/mountain_C_grass_trees.gltf", Vector3(-110, 0, 130), 70, 2.0)
	_spawn("res://assets/environment/nature/mountain_A_grass_trees.gltf", Vector3(140, 0, 120), -50, 2.3)


func _build_rocks() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var rocks := [
		"res://assets/environment/nature/rock_single_A.gltf",
		"res://assets/environment/nature/rock_single_B.gltf",
		"res://assets/environment/nature/rock_single_C.gltf",
		"res://assets/environment/nature/rock_single_D.gltf",
		"res://assets/environment/nature/rock_single_E.gltf",
	]
	for i in 35:
		var pos := Vector3(
			rng.randf_range(-MAP_HALF + 20.0, MAP_HALF - 20.0),
			0,
			rng.randf_range(-MAP_HALF + 20.0, MAP_HALF - 20.0)
		)
		if Vector2(pos.x, pos.z).length() < 12.0:
			continue
		_spawn(rocks[rng.randi() % rocks.size()], pos, rng.randf() * 360.0, rng.randf_range(1.0, 2.2))
