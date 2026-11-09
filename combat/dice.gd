class_name Dice
## Angriffswürfel. Alle Würfel sind sechsseitig; je nach Farbe zählen die Seiten
## 1 bis HIT_SIDES als Treffer, die übrigen Seiten sind keine Treffer.

enum DieColor { YELLOW, BLUE, GREEN, BLACK, RED }

const HIT_SIDES := {
	DieColor.YELLOW: 2,
	DieColor.BLUE: 3,
	DieColor.GREEN: 4,
	DieColor.BLACK: 5,
	DieColor.RED: 6,
}

const NAMES := {
	DieColor.YELLOW: "Gelb",
	DieColor.BLUE: "Blau",
	DieColor.GREEN: "Grün",
	DieColor.BLACK: "Schwarz",
	DieColor.RED: "Rot",
}


## Wirft alle Würfel aus `counts` (DieColor -> Anzahl).
## Ergebnis: { "hits": Gesamttreffer, "rolls": DieColor -> Array der geworfenen Augen }
static func roll(counts: Dictionary) -> Dictionary:
	var hits := 0
	var rolls := {}
	for color in counts:
		var faces: Array[int] = []
		for i in counts[color]:
			var face := randi_range(1, 6)
			faces.append(face)
			if face <= HIT_SIDES[color]:
				hits += 1
		if not faces.is_empty():
			rolls[color] = faces
	return {"hits": hits, "rolls": rolls}


## Mehrzeilige Beschreibung eines Wurfs für das Log.
static func describe(result: Dictionary) -> String:
	var lines: Array[String] = []
	for color in result.rolls:
		var faces: Array[int] = result.rolls[color]
		var hits := faces.filter(func(face): return face <= HIT_SIDES[color]).size()
		lines.append("  %d %s (Treffer 1-%d): %s -> %d Treffer" % [faces.size(), NAMES[color], HIT_SIDES[color], faces, hits])
	if lines.is_empty():
		lines.append("  keine Angriffswürfel")
	return "\n".join(lines)
