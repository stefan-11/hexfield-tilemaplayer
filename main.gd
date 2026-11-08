extends Node2D
## Lädt das Level, das im Inspector unter "Level Scene" eingetragen ist.

@export var level_scene: PackedScene


func _ready() -> void:
	add_child(level_scene.instantiate())
