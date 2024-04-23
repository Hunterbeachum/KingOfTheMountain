extends Path2D

var parent_is_boss : bool
var parent : Array = []
var pattern_data : Dictionary
var pattern_name : String = ""
var updates_queue : Array
var pattern_frames : int
var frame_delay : int
var current_delay : int
var loop_count : int
var spread : int
var style : String
var initial_velocity : Vector2 = Vector2(0.0, 0.0)
var initial_direction : String
var initial_damp : float
var speed : int = 0
@export var bullet_scene: PackedScene
@onready var bullet_path : PathFollow2D = $BulletPath
@onready var pattern_lifespan : Timer = $PatternLifespan
var drawing_pattern = false

func _ready():
	load_pattern()
	generate_pattern()

func load_pattern():
	pattern_data = GameState.data["pattern"][pattern_name]
	if pattern_data["position"] == "on_enemy":
		position = Vector2(0.0, 0.0)
	elif pattern_data["position"] == "center_screen":
		top_level = true #TODO is this needed?
		global_position = GameState.CENTERSCREEN
	speed = pattern_data["draw_speed"]
	var points_to_draw = pattern_data["points"]
	var curve = get_curve()
	for point in points_to_draw:
		curve.add_point(Vector2(point[0], point[1]))
		pattern_lifespan.start(pattern_data["loop_time"])
	loop_count = pattern_data["loop_count"]
	pattern_frames = 0
	frame_delay = pattern_data["frame_delay"]
	current_delay = frame_delay
	spread = pattern_data["spread"]
	style = pattern_data["style"]
	initial_velocity.x = pattern_data["initial_velocity"]
	initial_direction = pattern_data["initial_direction"]
	initial_damp = pattern_data["initial_damp"]
	for update in pattern_data["updates"]:
		updates_queue.append(update)
	add_to_group("active_patterns")
	pass

func _process(delta):
	pattern_frames += 1
	if not pattern_data.is_empty():
		generate_pattern()
	pass

func generate_pattern() -> void:
	if not updates_queue.is_empty():
		if pattern_data["loop_time"] - pattern_lifespan.time_left > updates_queue[0][1]:
			run_update(updates_queue.pop_front())
	if current_delay <= 0:
		if style == "free_fire":
			free_fire()
		elif style == "draw":
			draw()
		current_delay = frame_delay
	else:
		current_delay -= 1

func free_fire() -> void:
	for i in range(spread):
		var bullet = bullet_scene.instantiate()
		var bullet_direction
		if pattern_data["position"] == "on_enemy":
			bullet_direction = get_parent().position.angle_to_point(GameState.player_position)
		elif pattern_data["position"] == "center_screen":
			bullet_direction = GameState.CENTERSCREEN.angle_to_point(GameState.player_position)
		bullet.linear_velocity = initial_velocity.rotated(bullet_direction + (i - (spread / 2)) * PI / 15)
		bullet.add_to_group("bullets" + str(parent[1]))
		add_child(bullet)

func draw() -> void:
	for i in range(spread):
		var bullet_spawn_location = bullet_path.position
		bullet_spawn_location.x = bullet_spawn_location.x + (i - 1) * 100
		var direction
		if pattern_data["position"] == "center_screen":
			direction = GameState.CENTERSCREEN.angle_to_point(GameState.player_position)
		else:
			direction = GameState.boss_position.angle_to_point(GameState.player_position)
		var direction_list = []
		var bullet = bullet_scene.instantiate()
		bullet.position = bullet_spawn_location
		# bullet_velocity.rotated(n)
		bullet.linear_velocity = initial_velocity.rotated((direction) + (i - 1) * PI / 3 )
		add_child(bullet)
		var test = bullet.global_position
		bullet.add_to_group("bullets" + str(i))
		if bullet_path.progress_ratio >= 1.0:
			get_tree().call_group("bullets" + str(i), "set_linear_velocity", Vector2(100.0, 0.0).rotated((direction) - (i - 1) * PI / 30 ))
			drawing_pattern = false

func run_update(update_data : Array) -> void:
	pass

# reset the drawing loops
func _on_pattern_lifespan_timeout():
	loop_count -= 1
	if loop_count <= 0:
		pattern_data.clear()
		if not parent_is_boss:
			get_parent().enemy_movement(get_parent().leave_position)
	else:
		pattern_lifespan.start(pattern_data["loop_time"])

func set_parent(is_boss : bool, name : String, index : int, pattern : String):
	if is_boss:
		pass
	elif not is_boss:
		parent_is_boss = false
		parent.append(name)
		parent.append(index)
		pattern_name = pattern

func UpdateDrawingPattern() -> void:
	GameState.drawing_pattern = drawing_pattern
