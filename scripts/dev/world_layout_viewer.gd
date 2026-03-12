extends Node2D

const GeneratedExplorationProvider = preload("res://scripts/world/generated_exploration_provider.gd")

const WORLD_RECT := Rect2(Vector2(64,64), Vector2(1152,592))

@export var world_seed_string := "ALKU1234"
var actual_world_seed : int

var provider
var layout := {}

var camera: Camera2D

var drag := false
var last_mouse := Vector2.ZERO

func _ready():

	camera = $Camera2D
	actual_world_seed = world_seed_string.hash()
	generate_world()


func generate_world():

	provider = GeneratedExplorationProvider.new(actual_world_seed, WORLD_RECT)

	layout = provider.build_static_layout()

	queue_redraw()

	print("Generated seed:", actual_world_seed)


func _draw():

	if layout.is_empty():
		return

	# arena
	draw_rect(WORLD_RECT, Color(0.1,0.1,0.1), true)
	draw_rect(WORLD_RECT, Color.WHITE, false, 3)

	# zones
	for node in layout.get("layout_nodes",[]):

		var rect: Rect2 = node.get("rect", Rect2())
		var biome = node.get("biome","")

		var color = Color(0.4,0.4,0.4,0.25)

		match biome:
			"forest":
				color = Color(0.2,0.5,0.2,0.35)
			"meadow":
				color = Color(0.4,0.7,0.3,0.35)
			"street":
				color = Color(0.5,0.5,0.5,0.35)
			"housing":
				color = Color(0.6,0.4,0.3,0.35)
			"industrial":
				color = Color(0.4,0.4,0.6,0.35)

		draw_rect(rect, color, true)
		draw_rect(rect, color.lightened(0.4), false, 2)

		var center: Vector2 = node.get("center", Vector2.ZERO)

		draw_circle(center,6,Color.YELLOW)

	# corridors
	for link in layout.get("layout_links",[]):

		var points = link.get("corridor_points",[])

		for i in range(points.size()-1):

			draw_line(
				points[i],
				points[i+1],
				Color(0.7,0.9,1.0,0.4),
				6
			)

	# spawn
	var spawn = layout.get("spawn_hint",Vector2.ZERO)

	draw_circle(spawn,10,Color(1,0.9,0.3))


func _input(event):

	if event is InputEventKey and event.pressed:

		if event.keycode == KEY_R:
			world_seed_string = luo_satunnainen_merkkisarja(8)
			actual_world_seed = world_seed_string.hash()
			print("Uusi siemenmerkkisarja: ", world_seed_string)
			print("Moottorin käyttämä hash: ", actual_world_seed)
			# Kutsukaa tässä kentän uudelleengenerointi
			generate_world()

		if event.keycode == KEY_T:

			actual_world_seed = randi()
			generate_world()

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_MIDDLE:

			drag = event.pressed
			last_mouse = event.position

		if event.button_index == MOUSE_BUTTON_WHEEL_UP:

			camera.zoom *= 0.9

		if event.button_index == MOUSE_BUTTON_WHEEL_DOWN:

			camera.zoom *= 1.1

	if event is InputEventMouseMotion and drag:

		var delta = event.position - last_mouse
		camera.position -= delta * camera.zoom
		last_mouse = event.position

func luo_satunnainen_merkkisarja(pituus: int) -> String:
	var merkit = "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	var tulos = ""
	for i in range(pituus):
		tulos += merkit[randi() % merkit.length()]
	return tulos
