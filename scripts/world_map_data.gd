extends Node

## Points d'intérêt de la Vallée d'Aube (coordonnées XZ du monde).
## +X = Est, -Z = Nord (comme dans Godot).
## Autoload : WorldMap

const WORLD_HALF := 200.0

## type: village | forest | hills | mountain | quest
const POIS: Array[Dictionary] = [
	{
		"id": "boisclair",
		"name": "Boisclair",
		"pos": Vector2(-18, -22),
		"type": "village",
		"radius": 18.0,
		"quest": true,
	},
	{
		"id": "mira",
		"name": "Mira (église)",
		"pos": Vector2(-19.2, -36),
		"type": "village",
		"radius": 6.0,
		"quest": true,
	},
	{
		"id": "col_aube",
		"name": "Col de l'Aube",
		"pos": Vector2(-95, -55),
		"type": "mountain",
		"radius": 12.0,
		"quest": true,
	},
	{
		"id": "foret_emeraude",
		"name": "Forêt d'Émeraude",
		"pos": Vector2(55, -40),
		"type": "forest",
		"radius": 40.0,
		"quest": true,
	},
	{
		"id": "camp_grak",
		"name": "Camp de Grak",
		"pos": Vector2(88, -48),
		"type": "hills",
		"radius": 14.0,
		"quest": true,
	},
	{
		"id": "crypt",
		"name": "Crypte oubliée",
		"pos": Vector2(132, -99),
		"type": "mountain",
		"radius": 10.0,
		"quest": true,
	},
	{
		"id": "foret_ouest",
		"name": "Bois Brumeux",
		"pos": Vector2(-70, 50),
		"type": "forest",
		"radius": 35.0,
	},
	{
		"id": "foret_sud_est",
		"name": "Pins du Levant",
		"pos": Vector2(90, 70),
		"type": "forest",
		"radius": 30.0,
	},
	{
		"id": "collines_nord",
		"name": "Collines du Nord",
		"pos": Vector2(40, -70),
		"type": "hills",
		"radius": 22.0,
	},
	{
		"id": "collines_ouest",
		"name": "Crêtes Grises",
		"pos": Vector2(-50, -80),
		"type": "hills",
		"radius": 22.0,
	},
	{
		"id": "montagne_no",
		"name": "Pics d'Aube",
		"pos": Vector2(-120, -120),
		"type": "mountain",
		"radius": 35.0,
	},
	{
		"id": "montagne_ne",
		"name": "Dent de Givre",
		"pos": Vector2(130, -110),
		"type": "mountain",
		"radius": 35.0,
	},
]


func color_for_type(poi_type: String) -> Color:
	match poi_type:
		"village":
			return Color(0.82, 0.58, 0.28)
		"forest":
			return Color(0.22, 0.52, 0.26)
		"hills":
			return Color(0.45, 0.55, 0.32)
		"mountain":
			return Color(0.45, 0.48, 0.52)
		_:
			return Color(0.6, 0.6, 0.6)
