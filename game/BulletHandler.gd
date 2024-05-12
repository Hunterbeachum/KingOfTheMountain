extends Node2D

var parent_is_boss : bool
var parent : Array = []
var pattern_data : Dictionary
var pattern_name : String = ""
var pattern_frames : int
var frame_delay : int
var current_delay : int
var draw_time : float
var loop_time : float
var loop_count : int
var spread : int
var initial_spread : int
var spread_divisor : int
var style : String
var initial_velocity : Vector2 = Vector2(0.0, 0.0)
var target : Array
var direction : float
var initial_damp : float
var initial_angular_velocity : float
var startup_time : int = 0
var has_fired : bool = false
var updates : Array
var moving : bool = false
var rune_locations : Array = []
@export var bullet_scene: PackedScene
@export var rune_scene: PackedScene
var rune_path : Path2D
var rune_path_follower : PathFollow2D
@onready var loop_timer : Timer = $LoopTimer
@onready var draw_timer : Timer = $DrawTimer
@onready var update_timer : Timer = $UpdateTimer
var drawing_pattern = false
var stop_firing : bool = false

func _ready():
	var test = get_tree()
	load_pattern()
	for rune in rune_locations:
		generate_rune(rune)
	generate_pattern()

func load_pattern():
	pattern_data = GameState.data["pattern"][pattern_name].duplicate(true)
	for rune_position in pattern_data["position"]:
		rune_locations.append(rune_position)
	startup_time = pattern_data["startup_time"]
	var points_to_draw = pattern_data["points"]
	rune_path = Path2D.new()
	rune_path.curve = Curve2D.new()
	rune_path_follower = PathFollow2D.new()
	rune_path.add_child(rune_path_follower)
	for point in points_to_draw:
		rune_path.curve.add_point(Vector2(point[0], point[1]))
	draw_time = pattern_data["draw_time"]
	loop_time = pattern_data["loop_time"]
	loop_count = pattern_data["loop_count"]
	pattern_frames = 0
	frame_delay = pattern_data["frame_delay"]
	current_delay = frame_delay
	spread = pattern_data["spread"]
	initial_spread = spread
	spread_divisor = pattern_data["spread_PI_divisor"]
	style = pattern_data["style"]
	initial_velocity.x = pattern_data["initial_velocity"]
	target = pattern_data["target"]
	initial_damp = pattern_data["initial_damp"]
	initial_angular_velocity = pattern_data["initial_angular_velocity"] * .01
	for update in pattern_data["updates"]:
		updates.append(update)
	add_to_group("active_patterns")

func _process(delta):
	if not stop_firing:
		pattern_frames += 1
		if not pattern_data.is_empty():
			if not draw_timer.is_stopped():
				generate_pattern()
	pass

func generate_rune(rune_data : Array) -> void:
	var rune = rune_scene.instantiate()
	rune.parent_index = parent[1]
	rune.global_position = global_position
	rune.pattern_name = pattern_name
	rune.startup_time = startup_time
	if rune_data[0] == "global":
		rune.destination = Vector2(GameState.position_presets[rune_data[1]][0], GameState.position_presets[rune_data[1]][1])
		rune.top_level = true
	elif rune_data[0] == "on_enemy":
		rune.under_enemy = true
	elif rune_data[0] == "circle_enemy":
		rune.circling = 1
		rune.degrees = rune_data[1]
	elif rune_data[0] == "c.circle_enemy":
		rune.circling = -1
		rune.degrees = rune_data[1]
	elif rune_data[0] == "at_player":
		rune.destination = global_position + Vector2(700.0, 0.0).rotated(calculate_targeting(rune, "player"))
		rune.speed = rune_data[1]
		rune.fired_at_player = true
		rune.top_level = true
	rune.add_to_group("runes" + str(parent[1]))
	rune.add_to_group("runes" + str(parent[1]) + pattern_name)
	rune.connect("start_pattern", start_timers)
	SignalBus.node_added_to_scene.emit(rune)

func generate_pattern() -> void:
	if current_delay <= 0:
		for rune in get_tree().get_nodes_in_group("runes" + str(parent[1]) + pattern_name):
			if style == "free_fire":
				free_fire(rune)
			elif style == "fire_once":
				fire_once(rune)
			elif style == "growing_spread":
				growing_spread(rune)
			elif style == "spin":
				spin(rune)
			elif style == "draw":
				draw(rune)
			current_delay = frame_delay
		has_fired = true
	else:
		current_delay -= 1

func spin(rune : Node) -> void:
	initial_velocity = initial_velocity.rotated(PI/spread_divisor)
	free_fire(rune)

func free_fire(rune : Node) -> void:
	for i in range(spread):
		var bullet = bullet_scene.instantiate()
		bullet.linear_velocity = initial_velocity.rotated(calculate_targeting(rune, target[0]) + ((i + 0.5) - (spread / 2.0)) * PI / spread_divisor)
		bullet.set_updates(updates)
		bullet.add_to_group("bullets" + str(parent[1]) + pattern_name)
		bullet.global_position = rune.global_position
		SignalBus.node_added_to_scene.emit(bullet)

func fire_once(rune : Node) -> void:
	if not has_fired:
		for i in range(spread):
			var bullet = bullet_scene.instantiate()
			bullet.linear_velocity = initial_velocity.rotated(calculate_targeting(rune, target[0]) + ((i + 0.5) - (spread / 2.0)) * PI / spread_divisor)
			bullet.set_updates(updates)
			bullet.add_to_group("bullets" + str(parent[1]) + pattern_name)
			bullet.global_position = rune.global_position
			bullet.angular_velocity = initial_angular_velocity
			SignalBus.node_added_to_scene.emit(bullet)

func calculate_targeting(rune : Node, target_name : String) -> float:
	if target_name == "spin":
		initial_velocity = initial_velocity.rotated(PI / target[1])
		return initial_velocity.angle()
	if target_name == "player":
		return rune.global_position.angle_to_point(GameState.player_position)
	if target_name == "random":
		return randf_range(0.0, 2 * PI)
	else:
		return 0.0

func growing_spread(rune : Node) -> void:
	spread += 1
	free_fire(rune)

func draw(rune : Node) -> void:
	for i in range(spread):
		var bullet_spawn_location = rune_path_follower.global_position
		bullet_spawn_location.x = bullet_spawn_location.x + (i - 1) * 100
		var direction
		if pattern_data["position"] == "center_screen":
			direction = GameState.CENTERSCREEN.angle_to_point(GameState.player_position)
		else:
			direction = GameState.boss_position.angle_to_point(GameState.player_position)
		var direction_list = []
		var bullet = bullet_scene.instantiate()
		bullet.global_position = bullet_spawn_location
		# bullet_velocity.rotated(n)
		bullet.linear_velocity = initial_velocity.rotated((direction) + (i - 1) * PI / 3 )
		bullet.add_to_group("bullets" + str(parent[1]) + pattern_name)
		# First parent is Fairy or Boss scene, second is GameField scene
		SignalBus.node_added_to_scene.emit(bullet)
		var test = bullet.global_position
		bullet.add_to_group("bullets" + str(parent[1]) + pattern_name)
		if rune_path_follower.progress_ratio >= 1.0:
			get_tree().call_group("bullets" + str(parent[1]) + pattern_name, "set_linear_velocity", Vector2(100.0, 0.0).rotated((direction) - (i - 1) * PI / 30 ))
			drawing_pattern = false

# Reset the drawing loops
func _on_loop_timer_timeout():
	loop_count -= 1
	if loop_count <= 0:
		pattern_data.clear()
		if not parent_is_boss:
			get_parent().moving = true
	else:
		for rune in rune_locations:
			if rune[0] == "at_player":
				generate_rune(rune.duplicate(true))
		has_fired = false
		spread = initial_spread
		loop_timer.start(loop_time)
		draw_timer.start(draw_time)

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

func start_timers() -> void:
	draw_timer.start(draw_time)
	loop_timer.start(loop_time)

func set_stop_firing(argument : bool):
	stop_firing = argument
