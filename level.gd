extends TileMapLayer
## Spielbrett eines Levels. Levelspezifische Einstellungen stehen als Exports hier.

## Axiale Koordinate (q, r) des Hex-Felds, auf das die Kamera beim Start schaut.
@export var start_cell := Vector2i.ZERO
