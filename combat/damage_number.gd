class_name DamageNumber
extends Label
## Schwebende Schadenszahl: entsteht kurz über einer Einheit, steigt auf und blendet dann aus.

## Abstand über dem Mittelpunkt der Einheit, an dem die Zahl entsteht.
const SPAWN_OFFSET := 70.0
const RISE_DISTANCE := 60.0
const RISE_DURATION := 2.0
const FADE_DURATION := 1.0
const LABEL_SIZE := Vector2(120, 50)


## Zeigt "-amount" über `world_position`. `parent` sollte das Brett sein, damit die Zahl
## mit der Kamera mitwandert und eine besiegte (entfernte) Einheit überdauert.
static func spawn(parent: Node2D, world_position: Vector2, amount: int) -> void:
	var label := DamageNumber.new()
	label.text = "-%d" % amount
	label.position = parent.to_local(world_position) - Vector2(LABEL_SIZE.x / 2, SPAWN_OFFSET + LABEL_SIZE.y / 2)
	parent.add_child(label)


func _ready() -> void:
	size = LABEL_SIZE
	z_index = 100
	# Darf keine Klicks auf das Spielfeld abfangen.
	mouse_filter = MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	add_theme_font_size_override("font_size", 36)
	add_theme_color_override("font_color", Color(1, 0.25, 0.2))
	add_theme_color_override("font_outline_color", Color.BLACK)
	add_theme_constant_override("outline_size", 8)

	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - RISE_DISTANCE, RISE_DURATION) \
			.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, FADE_DURATION)
	tween.tween_callback(queue_free)
