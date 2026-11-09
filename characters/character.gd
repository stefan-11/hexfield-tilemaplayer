@tool
class_name Character
extends Node2D
## Eine Spielfigur auf dem Hex-Brett. Muss (indirekt) unter einem Brett-TileMapLayer hängen.
## Maßgeblich ist `cell`; die Pixel-Position wird daraus berechnet.
## Im Editor rastet die Figur beim Verschieben auf das nächste Hex ein.

enum Team { PLAYER, ENEMY }

## Wird ausgelöst, wenn die Figur ihren Weg (walk) fertig abgelaufen ist.
signal walk_finished

@export var type: CharacterType:
	set(value):
		type = value
		_update_visuals()
		update_configuration_warnings()
@export var team := Team.PLAYER
## Axiale Koordinate (q, r) des Felds, auf dem die Figur steht.
@export var cell := Vector2i.ZERO:
	set(value):
		cell = value
		_snap_to_cell()
## Sekunden pro Hex-Feld beim Laufen.
@export var step_duration := 0.18

var hp := 0
## Felder, die die Figur in dieser Runde noch laufen darf.
var moves_left := 0
## true, solange die Figur sichtbar einen Weg abläuft.
var is_walking := false


func _ready() -> void:
	_update_visuals()
	_snap_to_cell()
	if Engine.is_editor_hint():
		set_notify_transform(true)
	elif type:
		hp = type.max_hp


func _notification(what: int) -> void:
	# Nur im Editor: Verschieben mit der Maus setzt `cell` auf das nächste Hex.
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		var board := get_board()
		if board:
			cell = board.local_to_map(board.to_local(global_position))


## Setzt `cell` auf das Ende von `path` und lässt die Figur den Weg Feld für Feld ablaufen.
## Nur für Board.move_unit gedacht, das vorher die Regeln prüft.
func walk(path: Array[Vector2i]) -> void:
	is_walking = true
	cell = path.back()
	var board := get_board()
	var tween := create_tween()
	for step in path.slice(1):
		tween.tween_property(self, "global_position", board.to_global(board.map_to_local(step)), step_duration)
	await tween.finished
	is_walking = false
	_snap_to_cell()
	walk_finished.emit()


## Wird zu Beginn jeder Runde aufgerufen.
func reset_moves() -> void:
	moves_left = type.move_range if type else 0


func _get_configuration_warnings() -> PackedStringArray:
	if type == null:
		return ["Kein Charakter-Typ zugewiesen (Inspector: Type)."]
	return []


func get_board() -> TileMapLayer:
	var node := get_parent()
	while node and not node is TileMapLayer:
		node = node.get_parent()
	return node


func _snap_to_cell() -> void:
	if not is_inside_tree() or is_walking:
		return
	var board := get_board()
	if board == null:
		return
	var target := board.to_global(board.map_to_local(cell))
	# Nur bei Abweichung setzen, sonst löst jede Zuweisung erneut
	# NOTIFICATION_TRANSFORM_CHANGED aus.
	if not global_position.is_equal_approx(target):
		global_position = target


func _update_visuals() -> void:
	var sprite := get_node_or_null("Sprite2D") as Sprite2D
	if sprite == null:
		return
	sprite.texture = type.texture if type else null
	sprite.modulate = type.tint if type else Color.WHITE
