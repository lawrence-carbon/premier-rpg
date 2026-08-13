extends Node

## Sauvegarde / chargement (fichier user://eldoria_save.json).

const SAVE_PATH := "user://eldoria_save.json"
const SAVE_VERSION := 1

signal save_done
signal load_done


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node3D
	var narek := get_tree().get_first_node_in_group("narek")
	var alden := get_tree().get_first_node_in_group("alden")

	var data := {
		"version": SAVE_VERSION,
		"story": Story.to_dict(),
		"player": {},
		"narek": {},
		"alden_gave_quest": false,
		"goblins_alive": get_tree().get_nodes_in_group("goblins").size() > 0,
		"grak_alive": get_tree().get_first_node_in_group("grak") != null,
		"crypt_entrance": {},
		"crypt_crystal": {},
		"voiled": {},
	}

	if player:
		var pitch := 0.0
		if player.has_node("CameraPivot"):
			pitch = player.get_node("CameraPivot").rotation.x
		data["player"] = {
			"x": player.global_position.x,
			"y": player.global_position.y,
			"z": player.global_position.z,
			"rot_y": player.rotation.y,
			"pitch": pitch,
			"hp": int(player.get("hp")) if player.get("hp") != null else 8,
		}

	if narek and narek.has_method("get_save_data"):
		data["narek"] = narek.get_save_data()

	if alden and alden.has_method("get_save_data"):
		data["alden_gave_quest"] = bool(alden.get_save_data().get("gave_quest", false))

	var entrance := get_tree().get_first_node_in_group("crypt_entrance")
	if entrance and entrance.has_method("get_save_data"):
		data["crypt_entrance"] = entrance.get_save_data()

	var crystal := get_tree().get_first_node_in_group("crypt_crystal")
	if crystal and crystal.has_method("get_save_data"):
		data["crypt_crystal"] = crystal.get_save_data()

	var voiled := get_tree().get_first_node_in_group("voiled")
	if voiled and voiled.has_method("get_save_data"):
		data["voiled"] = voiled.get_save_data()

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_warning("Impossible d'écrire la sauvegarde.")
		return false
	file.store_string(JSON.stringify(data, "\t"))
	save_done.emit()
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return false
	_apply_save(parsed as Dictionary)
	load_done.emit()
	return true


func _apply_save(data: Dictionary) -> void:
	Story.from_dict(data.get("story", {}))

	var player := get_tree().get_first_node_in_group("player") as Node3D
	var narek := get_tree().get_first_node_in_group("narek")
	var alden := get_tree().get_first_node_in_group("alden")
	var story_ui := get_tree().get_first_node_in_group("story_ui")

	var pdata: Dictionary = data.get("player", {})
	if player and not pdata.is_empty():
		player.global_position = Vector3(
			float(pdata.get("x", 0.0)),
			float(pdata.get("y", 0.2)),
			float(pdata.get("z", 6.0))
		)
		player.rotation.y = float(pdata.get("rot_y", 0.0))
		if player.has_node("CameraPivot"):
			player.get_node("CameraPivot").rotation.x = float(pdata.get("pitch", 0.0))
		if player.get("hp") != null:
			player.set("hp", int(pdata.get("hp", 8)))
		if player.has_method("_emit_hp"):
			player.call("_emit_hp")

	var ndata: Dictionary = data.get("narek", {})
	if narek and narek.has_method("apply_save_data"):
		narek.apply_save_data(ndata)

	if alden and alden.has_method("apply_save_data"):
		alden.apply_save_data({"gave_quest": data.get("alden_gave_quest", false)})

	if not bool(data.get("goblins_alive", true)):
		for g in get_tree().get_nodes_in_group("goblins"):
			if is_instance_valid(g):
				g.queue_free()

	if not bool(data.get("grak_alive", true)):
		var grak := get_tree().get_first_node_in_group("grak")
		if grak and is_instance_valid(grak):
			grak.queue_free()

	var entrance := get_tree().get_first_node_in_group("crypt_entrance")
	if entrance and entrance.has_method("apply_save_data"):
		entrance.apply_save_data(data.get("crypt_entrance", {}))

	var crystal := get_tree().get_first_node_in_group("crypt_crystal")
	if crystal and crystal.has_method("apply_save_data"):
		crystal.apply_save_data(data.get("crypt_crystal", {}))

	var voiled := get_tree().get_first_node_in_group("voiled")
	if voiled and voiled.has_method("apply_save_data"):
		voiled.apply_save_data(data.get("voiled", {}))

	Story.intro_done = true
	Story.menu_open = false
	Story.map_open = false
	if Story.quest_active:
		Story.quest_updated.emit(Story.quest_text)


func new_game() -> void:
	Story.reset()
	get_tree().reload_current_scene()
