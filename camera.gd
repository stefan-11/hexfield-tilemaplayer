extends Camera2D
## Bewegt die Kamera über die Actions camera_left/right/up/down.
## Steht die Maus am Bildschirmrand, werden diese Actions ebenfalls ausgelöst.

const EDGE_ACTIONS := ["camera_left", "camera_right", "camera_up", "camera_down"]
const EDGE_DEVICE := 1000

## Geschwindigkeit in Bildschirm-Pixeln pro Sekunde.
@export var speed := 900.0
## Breite des Randbereichs in Pixeln, in dem die Maus die Kamera bewegt.
@export var edge_margin := 24.0
## Zusätzlicher Platz um das Spielfeld, bis zu dem gescrollt werden kann.
@export var border_margin := 64.0

var _bounds := Rect2()
var _has_bounds := false
var _edge_pressed := {}


## Begrenzt die Kamera auf das gemalte Spielfeld und zentriert sie darauf.
func fit_to_board(board: TileMapLayer) -> void:
	var cells := board.get_used_cells()
	if cells.is_empty():
		return
	var rect := Rect2(board.to_global(board.map_to_local(cells[0])), Vector2.ZERO)
	for cell in cells:
		rect = rect.expand(board.to_global(board.map_to_local(cell)))
	var half_tile := Vector2(board.tile_set.tile_size) / 2 + Vector2.ONE * border_margin
	_bounds = rect.grow_individual(half_tile.x, half_tile.y, half_tile.x, half_tile.y)
	_has_bounds = true
	position = _bounds.get_center()
	_clamp_to_bounds()
	reset_smoothing()


func _process(delta: float) -> void:
	_update_edge_actions()
	var direction := Input.get_vector("camera_left", "camera_right", "camera_up", "camera_down")
	position += direction * speed * delta / zoom
	_clamp_to_bounds()


func _update_edge_actions() -> void:
	var view_size := get_viewport_rect().size
	var mouse := get_viewport().get_mouse_position()
	var inside := Rect2(Vector2.ZERO, view_size).has_point(mouse) and DisplayServer.window_is_focused()
	var wanted := {
		"camera_left": inside and mouse.x < edge_margin,
		"camera_right": inside and mouse.x > view_size.x - edge_margin,
		"camera_up": inside and mouse.y < edge_margin,
		"camera_down": inside and mouse.y > view_size.y - edge_margin,
	}
	for action in EDGE_ACTIONS:
		if wanted[action] == _edge_pressed.get(action, false):
			continue
		_edge_pressed[action] = wanted[action]
		# Als eigenes "Gerät" senden, damit das Loslassen am Rand keine
		# gleichzeitig gehaltene Pfeiltaste mit loslässt (und umgekehrt).
		var event := InputEventAction.new()
		event.action = action
		event.pressed = wanted[action]
		event.device = EDGE_DEVICE
		Input.parse_input_event(event)


func _clamp_to_bounds() -> void:
	if not _has_bounds:
		return
	var half_view := get_viewport_rect().size / zoom / 2
	position.x = _clamp_axis(position.x, _bounds.position.x + half_view.x, _bounds.end.x - half_view.x)
	position.y = _clamp_axis(position.y, _bounds.position.y + half_view.y, _bounds.end.y - half_view.y)


## Ist das Spielfeld kleiner als der Bildschirm, bleibt die Kamera mittig stehen.
func _clamp_axis(value: float, low: float, high: float) -> float:
	if low > high:
		return (low + high) / 2
	return clampf(value, low, high)
