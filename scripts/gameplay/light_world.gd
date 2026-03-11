extends RefCounted
class_name LightWorld

var occluder_segments: Array = []
var material_patches: Array = []
var light_entities: Array = []
var metadata: Dictionary = {}

func _init(segments: Array = [], patches: Array = [], entities: Array = [], meta: Dictionary = {}) -> void:
	occluder_segments = segments.duplicate(true)
	material_patches = patches.duplicate(true)
	light_entities = entities.duplicate(true)
	metadata = meta.duplicate(true)
