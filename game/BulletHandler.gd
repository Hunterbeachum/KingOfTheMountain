extends Path2D

# Number of frames the pattern has existed
var pattern_frames : int
# Number of frames between each bullet instantiation
var frame_delay : int
# Number of frames until next bullet instantiation
var current_delay : int
var style : String
var initial_velocity : Vector2 = Vector2(0.0, 0.0)
var initial_direction : float
var initial_damp : float
var soft_tracking : bool
@export var bullet_scene: PackedScene
@onready var bullet_path : PathFollow2D = $BulletPath
@onready var pattern_lifespan : Timer = $PatternLifespan
@export var speed = 0
var drawing_pattern = true
var patterns_dict : Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/bullet_pattern_library.json"))

func _ready():
	load_pattern(GameState.current_pattern)
	generate_pattern()

func load_pattern(name: String):
	if patterns_dict[name]["position"] == "boss_position":
		global_position = GameState.boss_position
	elif patterns_dict[name]["position"] == "center_position":
		global_position = Vector2(0.0, 0.0)
	speed = patterns_dict[name]["draw_speed"]
	var points_to_draw = patterns_dict[name]["points"]
	var curve = get_curve()
	for point in points_to_draw:
		curve.add_point(Vector2(point[0], point[1]))
		pattern_lifespan.start(patterns_dict[name]["loop_time"])
	pattern_frames = 0
	frame_delay = patterns_dict[name]["frame_delay"]
	current_delay = frame_delay
	style = patterns_dict[name]["style"]
	initial_velocity.y = patterns_dict[name]["initial_velocity"]
	initial_direction = patterns_dict[name]["initial_direction"]
	initial_damp = patterns_dict[name]["initial_damp"]
	soft_tracking = patterns_dict[name]["soft_tracking"]
	add_to_group("active_patterns")
	pass

func _process(delta):
	pattern_frames += 1
	generate_pattern()
	pass

func generate_pattern():
	UpdateDrawingPattern()
	if drawing_pattern:
		if style == "drawn":
			bullet_path.progress += speed
			if current_delay <= 0:
				for i in range(3):
					var bullet_spawn_location = bullet_path.global_position
					bullet_spawn_location.x = bullet_spawn_location.x + (i - 1) * 100
					var direction = GameState.boss_position.angle_to_point(GameState.player_position)
					var direction_list = []
					var bullet = bullet_scene.instantiate()
					bullet.global_position = bullet_spawn_location
					# bullet_velocity.rotated(n)
					bullet.linear_velocity = initial_velocity.rotated((direction) + (i - 1) * PI / 10 )
					add_child(bullet)
					bullet.add_to_group("bullets" + str(i))
					if bullet_path.progress_ratio >= 1.0:
						get_tree().call_group("bullets" + str(i), "set_linear_velocity", Vector2(100.0, 0.0).rotated((direction) + (i - 1) * PI / 15 ))
						drawing_pattern = false
				current_delay = frame_delay
			else:
				current_delay -= 1
	pass

# reset the drawing loops
func _on_pattern_lifespan_timeout():
	drawing_pattern = true
	bullet_path.global_position = GameState.boss_position
	bullet_path.progress_ratio = 0.0

func UpdateDrawingPattern() -> void:
	GameState.drawing_pattern = drawing_pattern
