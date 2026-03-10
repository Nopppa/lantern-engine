extends RefCounted
class_name LightLabLayout

static func build_layout(base_alive_flip: bool) -> Dictionary:
	return {
		"dead_alive_cells": [
			{"rect": Rect2(Vector2(128, 136), Vector2(192, 128)), "value": 1.0},
			{"rect": Rect2(Vector2(752, 152), Vector2(168, 120)), "value": 0.55 if not base_alive_flip else 1.0}
		],
		"segments": [
			{"a": Vector2(64, 64), "b": Vector2(1216, 64), "normal": Vector2.DOWN, "material_id": "brick", "blocks_flashlight": true},
			{"a": Vector2(1216, 64), "b": Vector2(1216, 656), "normal": Vector2.LEFT, "material_id": "brick", "blocks_flashlight": true},
			{"a": Vector2(1216, 656), "b": Vector2(64, 656), "normal": Vector2.UP, "material_id": "brick", "blocks_flashlight": true},
			{"a": Vector2(64, 656), "b": Vector2(64, 64), "normal": Vector2.RIGHT, "material_id": "brick", "blocks_flashlight": true},
			{"a": Vector2(148, 282), "b": Vector2(334, 282), "normal": Vector2.DOWN, "material_id": "brick", "blocks_flashlight": true},
			{"a": Vector2(400, 300), "b": Vector2(400, 520), "normal": Vector2.RIGHT, "material_id": "wood", "blocks_flashlight": true},
			{"a": Vector2(510, 404), "b": Vector2(660, 404), "normal": Vector2.UP, "material_id": "wet", "blocks_flashlight": false},
			{"a": Vector2(840, 314), "b": Vector2(980, 314), "normal": Vector2.DOWN, "material_id": "mirror", "blocks_flashlight": true},
			{"a": Vector2(1048, 306), "b": Vector2(1048, 520), "normal": Vector2.LEFT, "material_id": "glass", "blocks_flashlight": false},
			{"a": Vector2(698, 280), "b": Vector2(698, 580), "normal": Vector2.RIGHT, "material_id": "brick", "blocks_flashlight": true}
		],
		"patches": [
			_sign_patch(Rect2(Vector2(120, 96), Vector2(200, 150)), "brick", "Brick", "Absorption bay", "absorbs heavily", "Compare beam loss and tiny spill"),
			_sign_patch(Rect2(Vector2(356, 96), Vector2(170, 150)), "wood", "Wood", "Diffuse bay", "soft diffusion", "Scatter is broad, not sharp"),
			_sign_patch(Rect2(Vector2(580, 96), Vector2(170, 150)), "wet", "Wet Stone", "Gloss bay", "glossier response", "Watch stronger streaks than dry surfaces"),
			_sign_patch(Rect2(Vector2(806, 96), Vector2(150, 150)), "mirror", "Mirror", "Routing bay", "strong reflection", "Cleanest secondary bounce"),
			_sign_patch(Rect2(Vector2(1012, 96), Vector2(150, 150)), "glass", "Glass", "Transmission bay", "partial transmission", "Read pass-through vs reflected remainder"),
			_sign_patch(Rect2(Vector2(124, 438), Vector2(252, 140)), "brick", "Dead / Alive", "Blend zone", "blend response", "Light should wake the floor, then fade"),
			_sign_patch(Rect2(Vector2(744, 436), Vector2(288, 160)), "wet", "Open Spawn", "Validation deck", "spawn validation", "Manual enemy checks with readable light lanes"),
			_sign_patch(Rect2(Vector2(420, 456), Vector2(112, 70)), "wet", "Shallow Water", "Water lane", "noticeable slowdown", "Visible drag, slight glossy light break-up"),
			_sign_patch(Rect2(Vector2(420, 526), Vector2(112, 86)), "wet", "Deep Water", "Water lane", "heavy slowdown", "Much stronger drag, stronger light disturbance"),
			_sign_patch(Rect2(Vector2(1078, 428), Vector2(116, 108)), "prism", "Prism Station", "Redirect bay", "redirect + excite", "Compare prism emission on nearby surfaces")
		],
		"prism_stations": [
			{"pos": Vector2(1138, 480), "radius": 26.0, "label": "Prism Station", "hint": "redirect + excite", "detail": "Beam reroutes here; prism light should read on nearby surfaces"}
		],
		"tree_trunks": [
			{"pos": Vector2(610, 318), "radius": 22.0, "label": "Tree trunk"},
			{"pos": Vector2(876, 520), "radius": 26.0, "label": "Tree trunk"}
		]
	}

static func _sign_patch(rect: Rect2, material_id: String, title: String, subtitle: String, hint: String, detail: String) -> Dictionary:
	return {
		"rect": rect,
		"material_id": material_id,
		"label": "%s %s" % [title, subtitle],
		"title": title,
		"subtitle": subtitle,
		"hint": hint,
		"detail": detail
	}
