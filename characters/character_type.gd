class_name CharacterType
extends Resource
## Werte und Grafik eines Charakter-Typs. Wird als .tres gespeichert und
## von beliebig vielen Charakteren in beliebigen Levels verwendet.

@export var display_name := ""
@export var texture: Texture2D
## Einfärbung der Grafik, z. B. um Platzhalter-Grafiken zu unterscheiden.
@export var tint := Color.WHITE
@export var max_hp := 10
@export var move_range := 3
