extends Node2D
## Lädt das Level, das im Inspector unter "Level Scene" eingetragen ist.

@export var level_scene: PackedScene

@onready var camera: Camera2D = $Camera


func _ready() -> void:
	var board: TileMapLayer = level_scene.instantiate()
	add_child(board)
	camera.fit_to_board(board)
