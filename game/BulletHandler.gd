extends Path2D

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
var target : String
var direction : float
var initial_damp : float
var draw_speed : int = 0
var has_fired : bool = false
var updates : Array
@export var bullet_scene: PackedScene
@onready var bullet_path : PathFollow2D = $BulletPath
@onready var loop_timer : Timer = $LoopTimer
@onready var draw_timer : Timer = $DrawTimer
@onready var update_timer : Timer = $UpdateTimer
var drawing_pattern = false
var stop_firing : bool = false

func _ready():
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
	initial_spread = spread
	spread_divisor = pattern_data["spread_PI_divisor"]
	style = pattern_data["style"]
	initial_velocity.x = pattern_data["initial_velocity"]
	target = pattern_data["target"]
	initial_damp = pattern_data["initial_damp"]
	for update in pattern_data["updates"]:
		updates.append(update)
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
	if current_delay <= 0:
		if style == "free_fire":
			free_fire()
		elif style == "fire_once":
			fire_once()
		elif style == "growing_spread":
			growing_spread()
		elif style == "spin":
			spin()
		elif style == "draw":
			draw()
		current_delay = frame_delay
	else:
		current_delay -= 1

func spin() -> void:
	initial_velocity = initial_velocity.rotated(PI/spread_divisor)
	free_fire()

func free_fire() -> void:
	for i in range(spread):
		var bullet = bullet_scene.instantiate()
		bullet.linear_velocity = initial_velocity.rotated(calculate_targeting() + ((i + 0.5) - (spread / 2.0)) * PI / spread_divisor)
		bullet.set_updates(updates)
		bullet.add_to_group("bullets" + str(parent[1]) + pattern_name)
		bullet.position = get_parent().position
		# First parent is Fairy or Boss scene, second is GameField scene
		get_parent().get_parent().add_child(bullet)

func fire_once() -> void:
	if not has_fired:
		for i in range(spread):
			var bullet = bullet_scene.instantiate()
			bullet.linear_velocity = initial_velocity.rotated(calculate_targeting() + (i - (spread / 2.0)) * PI / spread_divisor)
			bullet.set_updates(updates)
			bullet.add_to_group("bullets" + str(parent[1]) + pattern_name)
			bullet.position = get_parent().position
			# First parent is Fairy or Boss scene, second is GameField scene
			get_parent().get_parent().add_child(bullet)
	has_fired = true

func calculate_targeting() -> float:
	if style == "spin":
		return initial_velocity.angle()
	if target == "player":
		if pattern_data["position"] == "on_enemy":
			return get_parent().position.angle_to_point(GameState.player_position)
		elif pattern_data["position"] == "center_screen":
			return GameState.CENTERSCREEN.angle_to_point(GameState.player_position)
		else:
			return 0.0
	else:
		return 0.0

func growing_spread() -> void:
	spread += 1
	free_fire()

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
		bullet.add_to_group("bullets" + str(parent[1]) + pattern_name)
		# First parent is Fairy or Boss scene, second is GameField scene
		get_parent().get_parent().add_child(bullet)
		var test = bullet.global_position
		bullet.add_to_group("bullets" + str(parent[1]) + pattern_name)
		if bullet_path.progress_ratio >= 1.0:
			get_tree().call_group("bullets" + str(parent[1]) + pattern_name, "set_linear_velocity", Vector2(100.0, 0.0).rotated((direction) - (i - 1) * PI / 30 ))
			drawing_pattern = false

# reset the drawing loops
func _on_loop_timer_timeout():
	loop_count -= 1
	if loop_count <= 0:
		pattern_data.clear()
		if not parent_is_boss:
			get_parent().enemy_movement(get_parent().leave_position)
	else:
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

func stop_fire():
	stop_firing = true
