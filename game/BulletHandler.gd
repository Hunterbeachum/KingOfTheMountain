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
var target : Array
var direction : float
var initial_damp : float
var initial_angular_velocity : float
var draw_speed : int = 0
var has_fired : bool = false
var updates : Array
var texture_direction : float
var rune_alpha : float = 1.0
var moving : bool = false
var rune_locations : Array = []
@export var bullet_scene: PackedScene
@export var rune_scene: PackedScene
@onready var bullet_path : PathFollow2D = $BulletPath
@onready var loop_timer : Timer = $LoopTimer
@onready var draw_timer : Timer = $DrawTimer
@onready var update_timer : Timer = $UpdateTimer
var drawing_pattern = false
var stop_firing : bool = false

func _ready():
	load_pattern()
	for rune in rune_locations:
		generate_rune(rune)
	generate_pattern()

func load_pattern():
	pattern_data = GameState.data["pattern"][pattern_name].duplicate(true)
	for rune_position in pattern_data["position"]:
		rune_locations.append(rune_position)
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
	initial_angular_velocity = pattern_data["initial_angular_velocity"] * .01
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

func generate_rune(rune_data : Array) -> void:
	var rune = rune_scene.instantiate()
	if rune_data[0] == "global":
		rune.destination = Vector2(GameState.position_presets[rune_data[1]][0], GameState.position_presets[rune_data[1]][1])
	rune.add_to_group("runes" + str(parent[1]) + pattern_name)
	rune.position = global_position
	rune.top_level = true
	add_child(rune)

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
		bullet.linear_velocity = initial_velocity.rotated(calculate_targeting(rune) + ((i + 0.5) - (spread / 2.0)) * PI / spread_divisor)
		bullet.set_updates(updates)
		bullet.add_to_group("bullets" + str(parent[1]) + pattern_name)
		bullet.position = rune.position
		# First parent is Fairy or Boss scene, second is GameField scene
		get_parent().get_parent().add_child(bullet)

func fire_once(rune : Node) -> void:
	if not has_fired:
		for i in range(spread):
			var bullet = bullet_scene.instantiate()
			bullet.linear_velocity = initial_velocity.rotated(calculate_targeting(rune) + ((i + 0.5) - (spread / 2.0)) * PI / spread_divisor)
			bullet.set_updates(updates)
			bullet.add_to_group("bullets" + str(parent[1]) + pattern_name)
			bullet.global_position = rune.global_position
			bullet.angular_velocity = initial_angular_velocity
			# First parent is Fairy or Boss scene, second is GameField scene
			get_parent().get_parent().add_child(bullet)

func calculate_targeting(rune : Node) -> float:
	if target[0] == "spin":
		initial_velocity = initial_velocity.rotated(PI / target[1])
		return initial_velocity.angle()
	if target[0] == "player":
		return rune.position.angle_to_point(GameState.player_position)
	else:
		return 0.0

func growing_spread(rune : Node) -> void:
	spread += 1
	free_fire(rune)

func draw(rune : Node) -> void:
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

func set_rune_alpha(alpha : float) -> void:
	rune_alpha = alpha

func UpdateDrawingPattern() -> void:
	GameState.drawing_pattern = drawing_pattern

func stop_fire():
	stop_firing = true
