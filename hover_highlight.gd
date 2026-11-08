extends TileMapLayer
## Hebt das Hex-Feld unter der Maus farbig hervor.
## Muss als Kind des Spielbretts (TileMapLayer) in der Szene hängen.

@export var highlight_color := Color(0.4, 0.7, 1.0, 0.45)

@onready var board: TileMapLayer = get_parent()

var _hovered_cell := Vector2i.ZERO
var _has_hover := false


func _ready() -> void:
	tile_set = board.tile_set
	modulate = highlight_color


func _process(_delta: float) -> void:
	var cell := board.local_to_map(board.get_local_mouse_position())
	var on_board := board.get_cell_source_id(cell) != -1

	if on_board and _has_hover and cell == _hovered_cell:
		return

	if _has_hover:
		erase_cell(_hovered_cell)
		_has_hover = false

	if on_board:
		# Dasselbe Tile wie auf dem Brett, nur eingefärbt darüber gelegt.
		set_cell(cell, board.get_cell_source_id(cell), board.get_cell_atlas_coords(cell))
		_hovered_cell = cell
		_has_hover = true
