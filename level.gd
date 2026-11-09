class_name Board
extends TileMapLayer
## Spielbrett eines Levels. Levelspezifische Einstellungen stehen als Exports hier.
## Führt außerdem Buch darüber, welcher Charakter auf welchem Feld steht.

## Axiale Koordinate (q, r) des Hex-Felds, auf das die Kamera beim Start schaut.
@export var start_cell := Vector2i.ZERO

## Hex-Koordinate -> Character
var _units := {}

@onready var units_root: Node2D = $Units
## Overlay für die erreichbaren Felder der ausgewählten Einheit.
@onready var reach_layer: TileMapLayer = $Reach


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


func get_units() -> Array[Character]:
	var units: Array[Character] = []
	units.assign(_units.values())
	return units


## Alle Felder, die `unit` mit ihrer Restreichweite erreichen kann, als
## Hex-Koordinate -> Wegkosten. Andere Figuren und Lücken im Brett blockieren.
func get_reachable(unit: Character) -> Dictionary:
	var costs := {unit.cell: 0}
	var frontier: Array[Vector2i] = [unit.cell]
	while not frontier.is_empty():
		var current: Vector2i = frontier.pop_front()
		var next_cost: int = costs[current] + 1
		if next_cost > unit.moves_left:
			continue
		for neighbor in get_surrounding_cells(current):
			if costs.has(neighbor) or get_cell_source_id(neighbor) == -1 or _units.has(neighbor):
				continue
			costs[neighbor] = next_cost
			frontier.append(neighbor)
	costs.erase(unit.cell)
	return costs


## Bewegt `unit` nach `to` und zieht die Wegkosten von der Restreichweite ab.
## Gibt false zurück (und bewegt nichts), wenn `to` nicht erreichbar ist.
func move_unit(unit: Character, to: Vector2i) -> bool:
	var reachable := get_reachable(unit)
	if not reachable.has(to):
		return false
	_units.erase(unit.cell)
	unit.cell = to
	unit.moves_left -= reachable[to]
	_units[to] = unit
	return true
