extends Node3D

## Place le décor du monde (village, forêt, collines…).
## Les modèles viennent du pack KayKit Medieval (même style que le héros).

const PROP_SCALE := 6.0
const MAP_HALF := 180.0 # le sol va de -180 à +180
## Distance mini entre deux arbres (pour pouvoir se faufiler)
const TREE_MIN_SPACING := 1.0
const DOOR_SCENE := preload("res://scenes/building_door.tscn")

@onready var decor: Node3D = $Decor


func _ready() -> void:
	_build_village()
	# Forêts plus aérées : rayon plus grand, moins d'arbres
	_build_forest(Vector3(55, 0, -40), 70, 36)
	_build_forest(Vector3(-70, 0, 50), 60, 28)
	_build_forest(Vector3(90, 0, 70), 55, 24)
	_build_hills()
	_build_rocks()
	_build_mountains()


func _spawn(
	path: String,
	pos: Vector3,
	yaw_deg: float = 0.0,
	scale_mul: float = 1.0,
	collision: String = "trimesh"
) -> Node3D:
	var packed: PackedScene = load(path)
	if packed == null:
		push_warning("Impossible de charger: " + path)
		return null
	var node: Node3D = packed.instantiate()
	node.position = pos
	node.rotation_degrees.y = yaw_deg
	node.scale = Vector3.ONE * (PROP_SCALE * scale_mul)
	decor.add_child(node)
	match collision:
		"trimesh":
			_add_trimesh_collisions(node)
		"trunk":
			# Petit tronc seulement → on passe entre les feuillages
			_add_trunk_collision(node)
		_:
			pass
	return node


func _add_trimesh_collisions(root: Node) -> void:
	for mesh in root.find_children("*", "MeshInstance3D", true, false):
		mesh.create_trimesh_collision()


func _add_trunk_collision(root: Node3D) -> void:
	# Collision fine au centre (espace local, avant l'échelle du nœud)
	var body := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var cylinder := CylinderShape3D.new()
	cylinder.radius = 0.08
	cylinder.height = 1.6
	shape.shape = cylinder
	shape.position = Vector3(0.0, 0.8, 0.0)
	body.add_child(shape)
	root.add_child(body)


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
	# Portes : E pour entrer (intérieur commun sous le village)
	_add_door("Maison", base + Vector3(1.5, 0, 5.5), 0)
	_add_door("Maison", base + Vector3(10, 0, 9.5), 0)
	_add_door("Maison", base + Vector3(-6, 0, 13), 0)
	_add_door("Taverne", base + Vector3(4, 0, -5.5), 0)
	_add_door("Forge", base + Vector3(-10, 0, -1), 0)
	_add_door("Marché", base + Vector3(14, 0, 1.5), 0)
	_add_door("Église", base + Vector3(-4, 0, -14.8), 0)
	_add_door("Scierie", base + Vector3(16, 0, 14.5), 0)
	# Arbres autour du village (espacés, collision tronc)
	for i in 6:
		var a := float(i) * TAU / 6.0
		_spawn(
			"res://assets/environment/nature/tree_single_A.gltf",
			base + Vector3(cos(a) * 26.0, 0, sin(a) * 22.0),
			i * 40.0,
			0.9 + (i % 3) * 0.15,
			"trunk"
		)


func _add_door(building_name: String, pos: Vector3, yaw_deg: float) -> void:
	var door: Node3D = DOOR_SCENE.instantiate()
	door.set("building_name", building_name)
	door.position = pos
	door.rotation_degrees.y = yaw_deg
	decor.add_child(door)


func _build_forest(center: Vector3, radius: float, count: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(abs(center.x * 1000.0 + center.z))
	# Uniquement des arbres isolés (pas de bouquets compacts)
	var tree_paths := [
		"res://assets/environment/nature/tree_single_A.gltf",
		"res://assets/environment/nature/tree_single_B.gltf",
	]
	var placed: Array[Vector2] = []
	var attempts := 0
	var max_attempts := count * 12
	while placed.size() < count and attempts < max_attempts:
		attempts += 1
		var angle := rng.randf() * TAU
		# Prefère le milieu/extérieur du cercle pour des clairières au centre
		var dist := rng.randf_range(radius * 0.25, radius)
		var pos := center + Vector3(cos(angle) * dist, 0.0, sin(angle) * dist)
		# Évite le village
		if Vector2(pos.x + 18.0, pos.z + 22.0).length() < 32.0:
			continue
		var p2 := Vector2(pos.x, pos.z)
		var too_close := false
		for other in placed:
			if p2.distance_to(other) < TREE_MIN_SPACING:
				too_close = true
				break
		if too_close:
			continue
		placed.append(p2)
		var path: String = tree_paths[rng.randi() % tree_paths.size()]
		_spawn(path, pos, rng.randf() * 360.0, rng.randf_range(0.9, 1.25), "trunk")


func _build_hills() -> void:
	# Collines sans gros blocs d'arbres collés (on garde le relief)
	_spawn("res://assets/environment/nature/hills_A.gltf", Vector3(40, 0, -70), 0, 1.2)
	_spawn("res://assets/environment/nature/hills_B.gltf", Vector3(-50, 0, -80), 45, 1.3)
	_spawn("res://assets/environment/nature/hills_C.gltf", Vector3(70, 0, 30), -20, 1.2)
	_spawn("res://assets/environment/nature/hills_A.gltf", Vector3(-30, 0, 90), 90, 1.4)
	_spawn("res://assets/environment/nature/hills_B.gltf", Vector3(100, 0, -20), 10, 1.3)
	_spawn("res://assets/environment/nature/hill_single_A.gltf", Vector3(15, 0, 35), 0, 1.5)
	_spawn("res://assets/environment/nature/hill_single_B.gltf", Vector3(-40, 0, 20), 60, 1.6)
	_spawn("res://assets/environment/nature/hill_single_C.gltf", Vector3(25, 0, -50), -30, 1.4)
	# Colline de la Crypte oubliée (entrée collée au flanc sud)
	_spawn("res://assets/environment/nature/hill_single_A.gltf", Vector3(132.3, 0, -102), 0, 1.35)
	# Quelques arbres espacés sur les collines
	_spawn("res://assets/environment/nature/tree_single_B.gltf", Vector3(38, 0, -68), 10, 1.0, "trunk")
	_spawn("res://assets/environment/nature/tree_single_A.gltf", Vector3(48, 0, -74), -20, 1.1, "trunk")
	_spawn("res://assets/environment/nature/tree_single_B.gltf", Vector3(-46, 0, -78), 40, 1.0, "trunk")
	_spawn("res://assets/environment/nature/tree_single_A.gltf", Vector3(138, 0, -105), -15, 1.0, "trunk")


func _build_mountains() -> void:
	# Montagnes : collision du relief, sans forcer les arbres intégrés
	_spawn("res://assets/environment/nature/mountain_A_grass.gltf", Vector3(-120, 0, -120), 20, 2.0)
	_spawn("res://assets/environment/nature/mountain_B_grass.gltf", Vector3(130, 0, -110), -15, 2.2)
	_spawn("res://assets/environment/nature/mountain_C_grass.gltf", Vector3(-110, 0, 130), 70, 2.0)
	_spawn("res://assets/environment/nature/mountain_A_grass.gltf", Vector3(140, 0, 120), -50, 2.3)


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
