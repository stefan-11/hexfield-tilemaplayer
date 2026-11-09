class_name Board
extends TileMapLayer
## Spielbrett eines Levels. Levelspezifische Einstellungen stehen als Exports hier.
## Führt außerdem Buch darüber, welcher Charakter auf welchem Feld steht.

## Axiale Koordinate (q, r) des Hex-Felds, auf das die Kamera beim Start schaut.
@export var start_cell := Vector2i.ZERO

## Hex-Koordinate -> Character
var _units := {}
## Wegfindungs-Graph aller begehbaren Felder. Wird in _ready aus den gemalten Tiles aufgebaut.
var _astar := HexAStar.new()

@onready var units_root: Node2D = $Units
## Overlay für die erreichbaren Felder der ausgewählten Einheit.
@onready var reach_layer: TileMapLayer = $Reach
## Overlay für den Weg, den die ausgewählte Einheit zum Feld unter der Maus nehmen würde.
@onready var path_layer: TileMapLayer = $Path


func _ready() -> void:
	for unit in units_root.get_children():
		if not unit is Character:
			continue
		if get_cell_source_id(unit.cell) == -1:
			push_warning("%s steht auf %s, dort ist kein Spielfeld." % [unit.name, unit.cell])
		if _units.has(unit.cell):
			push_warning("%s und %s stehen beide auf %s." % [unit.name, _units[unit.cell].name, unit.cell])
		_units[unit.cell] = unit
	_build_astar()


func get_unit_at(cell: Vector2i) -> Character:
	return _units.get(cell)


func get_units() -> Array[Character]:
	var units: Array[Character] = []
	units.assign(_units.values())
	return units


## Kosten, um `cell` zu betreten (Custom Data Layer "move_cost" im TileSet).
## 0 oder kleiner bedeutet unpassierbar; Felder ohne Tile sind ebenfalls unpassierbar.
func get_move_cost(cell: Vector2i) -> int:
	var data := get_cell_tile_data(cell)
	return data.get_custom_data("move_cost") if data else 0


## Alle Felder, die `unit` mit ihrer Restreichweite erreichen kann, als
## Hex-Koordinate -> Wegkosten (Dijkstra). Andere Figuren und unpassierbares Terrain blockieren.
func get_reachable(unit: Character) -> Dictionary:
	var costs := {unit.cell: 0}
	var done := {}
	var open: Array[Vector2i] = [unit.cell]
	while not open.is_empty():
		# Immer das Feld mit den bisher geringsten Kosten als Nächstes abarbeiten.
		var best := 0
		for i in range(1, open.size()):
			if costs[open[i]] < costs[open[best]]:
				best = i
		var current: Vector2i = open.pop_at(best)
		if done.has(current):
			continue
		done[current] = true
		for neighbor in get_surrounding_cells(current):
			var step := get_move_cost(neighbor)
			if step <= 0 or _units.has(neighbor):
				continue
			var new_cost: int = costs[current] + step
			if new_cost > unit.moves_left or new_cost >= costs.get(neighbor, INF):
				continue
			costs[neighbor] = new_cost
			open.append(neighbor)
	costs.erase(unit.cell)
	return costs


## Günstigster Weg von `from` nach `to` inklusive Start- und Zielfeld, unabhängig von
## der Reichweite. Leer, wenn es keinen Weg gibt. Andere Figuren blockieren.
func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]:
	var path: Array[Vector2i] = []
	var from_id := HexAStar.cell_id(from)
	var to_id := HexAStar.cell_id(to)
	if not _astar.has_point(from_id) or not _astar.has_point(to_id):
		return path
	var blocked: Array[int] = []
	for cell in _units:
		var id := HexAStar.cell_id(cell)
		if cell != from and _astar.has_point(id):
			_astar.set_point_disabled(id, true)
			blocked.append(id)
	for point in _astar.get_point_path(from_id, to_id):
		path.append(Vector2i(point))
	for id in blocked:
		_astar.set_point_disabled(id, false)
	return path


## Ob `attacker` `target` jetzt angreifen darf: gegnerisches Team, in Angriffsreichweite
## (Hex-Distanz, Hindernisse spielen keine Rolle) und in dieser Runde noch nicht angegriffen.
func can_attack(attacker: Character, target: Character) -> bool:
	return attacker.team != target.team \
			and not attacker.has_attacked \
			and HexAStar.distance(attacker.cell, target.cell) <= attacker.type.attack_range


## Führt einen Angriff aus: wirft alle Angriffswürfel von `attacker` und zieht die Treffer
## von den HP von `target` ab. Besiegte Figuren (0 HP) werden vom Brett entfernt.
## Gibt das Würfelergebnis zurück (siehe Dice.roll), oder {} wenn der Angriff nicht erlaubt ist.
func attack(attacker: Character, target: Character) -> Dictionary:
	if not can_attack(attacker, target):
		return {}
	attacker.has_attacked = true
	var result := Dice.roll(attacker.attack_dice)
	var hp_before := target.hp
	target.take_damage(result.hits)
	print("%s greift %s an (Distanz %d):\n%s\n  = %d Treffer, %s: %d -> %d HP" % [
		attacker.type.display_name, target.type.display_name,
		HexAStar.distance(attacker.cell, target.cell), Dice.describe(result),
		result.hits, target.type.display_name, hp_before, target.hp])
	if target.hp <= 0:
		print("  %s ist besiegt." % target.type.display_name)
		_units.erase(target.cell)
		target.queue_free()
	return result


func _build_astar() -> void:
	_astar.clear()
	for cell in get_used_cells():
		var cost := get_move_cost(cell)
		if cost > 0:
			_astar.add_point(HexAStar.cell_id(cell), Vector2(cell), cost)
	for cell in get_used_cells():
		var id := HexAStar.cell_id(cell)
		if not _astar.has_point(id):
			continue
		for neighbor in get_surrounding_cells(cell):
			var neighbor_id := HexAStar.cell_id(neighbor)
			if _astar.has_point(neighbor_id):
				_astar.connect_points(id, neighbor_id)


## Bewegt `unit` entlang `path` (inklusive Startfeld, z. B. aus find_path) und zieht die
## Wegkosten von der Restreichweite ab. Der Spielzustand ist sofort aktualisiert; die Figur
## läuft den Weg danach sichtbar ab (Character.walk_finished).
## Gibt false zurück (und bewegt nichts), wenn der Weg ungültig oder zu teuer ist.
func move_unit(unit: Character, path: Array[Vector2i]) -> bool:
	if path.size() < 2 or path[0] != unit.cell:
		return false
	var cost := 0
	for i in range(1, path.size()):
		var cell := path[i]
		if not cell in get_surrounding_cells(path[i - 1]) or get_move_cost(cell) <= 0 or _units.has(cell):
			return false
		cost += get_move_cost(cell)
	if cost > unit.moves_left:
		return false
	_units.erase(unit.cell)
	_units[path.back()] = unit
	unit.moves_left -= cost
	unit.walk(path)
	return true
