extends TileMapLayer
## Spielbrett eines Levels. Levelspezifische Einstellungen stehen als Exports hier.
## Führt außerdem Buch darüber, welcher Charakter auf welchem Feld steht.

## Axiale Koordinate (q, r) des Hex-Felds, auf das die Kamera beim Start schaut.
@export var start_cell := Vector2i.ZERO

## Hex-Koordinate -> Character
var _units := {}

@onready var units_root: Node2D = $Units


func _ready() -> void:
	for unit in units_root.get_children():
		if not unit is Character:
			continue
		if get_cell_source_id(unit.cell) == -1:
			push_warning("%s steht auf %s, dort ist kein Spielfeld." % [unit.name, unit.cell])
		if _units.has(unit.cell):
			push_warning("%s und %s stehen beide auf %s." % [unit.name, _units[unit.cell].name, unit.cell])
		_units[unit.cell] = unit


func get_unit_at(cell: Vector2i) -> Character:
	return _units.get(cell)


func move_unit(unit: Character, to: Vector2i) -> void:
	_units.erase(unit.cell)
	unit.cell = to
	_units[to] = unit
