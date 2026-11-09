extends TileMapLayer
## Overlay, das eine beliebige Menge Hex-Felder farbig hervorhebt.
## Muss als Kind des Spielbretts (TileMapLayer) in der Szene hängen.

@export var highlight_color := Color(0.4, 1.0, 0.5, 0.4)

@onready var board: TileMapLayer = get_parent()


func _ready() -> void:
	tile_set = board.tile_set
	modulate = highlight_color


func show_cells(cells: Array) -> void:
	clear()
	for cell in cells:
		set_cell(cell, board.get_cell_source_id(cell), board.get_cell_atlas_coords(cell))
