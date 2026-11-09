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
## Hex-Distanz, aus der ein Gegner angegriffen werden kann (1 = nur Nachbarfelder).
@export var attack_range := 1

## Startwerte der Angriffswürfel. Jede Figur bekommt beim Start eine eigene Kopie
## (Character.attack_dice), die sich im Spiel durch Verbesserungen ändern kann.
@export_group("Angriffswürfel")
@export var dice_yellow := 0
@export var dice_blue := 0
@export var dice_green := 0
@export var dice_black := 0
@export var dice_red := 0


## Angriffswürfel als Dice.DieColor -> Anzahl.
func get_attack_dice() -> Dictionary:
	return {
		Dice.DieColor.YELLOW: dice_yellow,
		Dice.DieColor.BLUE: dice_blue,
		Dice.DieColor.GREEN: dice_green,
		Dice.DieColor.BLACK: dice_black,
		Dice.DieColor.RED: dice_red,
	}
