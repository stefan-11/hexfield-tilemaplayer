class_name HexAStar
extends AStar2D
## AStar auf axialen Hex-Koordinaten. Die Position jedes Punkts ist seine Hex-Koordinate (q, r),
## Punkte sind nur mit ihren Hex-Nachbarn verbunden. Die Terrain-Kosten eines Felds stehen
## als weight_scale am Punkt und werden beim Betreten berechnet.


static func cell_id(cell: Vector2i) -> int:
	# Eindeutige, nicht-negative ID auch für negative Koordinaten.
	return (cell.x + 32768) * 65536 + (cell.y + 32768)


func _compute_cost(_from_id: int, _to_id: int) -> float:
	# Nur Nachbarn sind verbunden: ein Schritt kostet 1, multipliziert mit weight_scale des Ziels.
	return 1.0


func _estimate_cost(from_id: int, end_id: int) -> float:
	# Hex-Distanz; unterschätzt nie, da jedes Feld mindestens 1 kostet.
	var d := Vector2i(get_point_position(from_id) - get_point_position(end_id))
	return (absi(d.x) + absi(d.y) + absi(d.x + d.y)) / 2.0
