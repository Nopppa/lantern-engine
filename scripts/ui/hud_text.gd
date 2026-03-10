extends RefCounted
class_name HudText

static func bar(value: float, max_value: float, width: int = 14) -> String:
	var filled := int(round(clamp(value / max(max_value, 0.001), 0.0, 1.0) * width))
	return "[color=#f8f8f2]%s[/color][color=#4a5468]%s[/color]" % ["■".repeat(filled), "■".repeat(width - filled)]
