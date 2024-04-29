extends Path2D

var parent_is_boss : bool
var parent : Array = []
var pattern_data : Dictionary
var pattern_name : String = ""
var updates_queue : Array
var active_updates : Array
var pattern_frames : int
var frame_delay : int
var current_delay : int
var draw_time : float
var loop_time : float
var loop_count : int
var spread : int
var style : String
var initial_velocity : Vector2 = Vector2(0.0, 0.0)
var target : String
var direction : float
var initial_damp : float
var draw_speed : int = 0
var has_fired : bool = false
@export var bullet_scene: PackedScene
@onready var bullet_path : PathFollow2D = $BulletPath
@onready var loop_timer : Timer = $LoopTimer
@onready var draw_timer : Timer = $DrawTimer
@onready var update_timer : Timer = $UpdateTimer
var drawing_pattern = false
var stop_firing : bool = false

func _ready():
	var test = GameState.data["pattern"][pattern_name]
	load_pattern()
	generate_pattern()

func load_pattern():
	pattern_data = GameState.data["pattern"][pattern_name].duplicate(true)
	if pattern_data["position"] == "on_enemy":
		position = Vector2(0.0, 0.0)
	elif pattern_data["position"] == "center_screen":
		top_level = true #TODO is this needed?
		global_position = GameState.CENTERSCREEN
	draw_speed = pattern_data["draw_speed"]
	var points_to_draw = pattern_data["points"]
	var curve = get_curve()
	for point in points_to_draw:
		curve.add_point(Vector2(point[0], point[1]))
	draw_time = pattern_data["draw_time"]
	draw_timer.start(draw_time)
	loop_time = pattern_data["loop_time"]
	loop_timer.start(loop_time)
	loop_count = pattern_data["loop_count"]
	pattern_frames = 0
	frame_delay = pattern_data["frame_delay"]
	current_delay = frame_delay
	spread = pattern_data["spread"]
	style = pattern_data["style"]
	initial_velocity.x = pattern_data["initial_velocity"]
	target = pattern_data["target"]
	initial_damp = pattern_data["initial_damp"]
	for update in pattern_data["updates"]:
		updates_queue.append(update)
	add_to_group("active_patterns")
	pass

func _process(delta):
	if not stop_firing:
		pattern_frames += 1
		if not pattern_data.is_empty():
			if not draw_timer.is_stopped():
				generate_pattern()
	pass

func generate_pattern() -> void:
	if not updates_queue.is_empty():
		if pattern_data["draw_time"] - draw_timer.time_left > updates_queue[0][1]:
			load_update(updates_queue.pop_front())
	if not active_updates.is_empty():
		run_update(active_updates)
	if current_delay <= 0:
		if style == "free_fire":
			free_fire()
		elif style == "fire_once":
			fire_once()
		elif style == "draw":
			draw()
		current_delay = frame_delay
	else:
		current_delay -= 1

func free_fire() -> void:
	for i in range(spread):
		var bullet = bullet_scene.instantiate()
		bullet.linear_velocity = initial_velocity.rotated(calculate_targeting() + (i - (spread / 2)) * PI / 15)
		bullet.add_to_group("bullets" + str(parent[1]))
		add_child(bullet)

func fire_once() -> void:
	if not has_fired:
		for i in range(spread):
			var bullet = bullet_scene.instantiate()
			bullet.linear_velocity = initial_velocity.rotated(calculate_targeting() + (i - (spread / 2)) * PI / 15)
			bullet.add_to_group("bullets" + str(parent[1]))
			add_child(bullet)
	has_fired = true

func calculate_targeting() -> float:
	if target == "player":
		if pattern_data["position"] == "on_enemy":
			return get_parent().position.angle_to_point(GameState.player_position)
		elif pattern_data["position"] == "center_screen":
			return GameState.CENTERSCREEN.angle_to_point(GameState.player_position)
		else:
			return 0.0
	else:
		return 0.0

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
		bullet.add_to_group("bullets" + str(parent[1]))
		add_child(bullet)
		var test = bullet.global_position
		bullet.add_to_group("bullets" + str(parent[1]) + "drawn" + str(i))
		if bullet_path.progress_ratio >= 1.0:
			get_tree().call_group("bullets" + str(parent[1]) + "drawn" + str(i), "set_linear_velocity", Vector2(100.0, 0.0).rotated((direction) - (i - 1) * PI / 30 ))
			drawing_pattern = false

func load_update(update_data : Array) -> void:
	active_updates.append(update_data)
	var update_name = update_data[0]
	await get_tree().create_timer(update_data[2]).timeout
	active_updates.erase(update_data)
	pass

func run_update(active_update_list : Array):
	for active_update in active_update_list:
		var update_name = active_update[0]
		if update_name == "spin":
			if current_delay <= 0:
				initial_velocity = initial_velocity.rotated(active_update[3] * PI/15)
		elif update_name == "accelerate":
			get_tree().call_group("bullets" + str(parent[1]), "accelerate", active_update[1], active_update[3])

# reset the drawing loops
func _on_loop_timer_timeout():
	loop_count -= 1
	if loop_count <= 0:
		pattern_data.clear()
		if not parent_is_boss:
			get_parent().enemy_movement(get_parent().leave_position)
	else:
		loop_timer.start(loop_time)
		draw_timer.start(loop_time)

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

func stop_fire():
	stop_firing = true
