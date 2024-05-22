extends Node2D

var wave_data : Dictionary
var enemy_count : int
var remaining_enemy_count : int
var spawn_interval : float
var enemy_name : String
var enemy_path_points : Array
var spawn_offset : Vector2
var distance_to_stop_point : float
var fire_while_moving : bool
var drop_item : String
var wave_enemy_index : int = 0
var finished_spawning : bool = false
@export var enemy_scene : PackedScene

func _ready():
	name = "ENEMY_WAVE_HANDLER"
	SignalBus.pause.connect(pause)
	load_enemy_wave_data()
	start_spawn_cycle()

func load_enemy_wave_data() -> void:
	enemy_count = wave_data["enemy_count"]
	remaining_enemy_count = enemy_count
	spawn_interval = wave_data["spawn_interval"]
	enemy_name = wave_data["enemy_name"]
	fire_while_moving = wave_data["fire_while_moving"]
	var start_position = Vector2(GameState.position_presets[wave_data["spawn_position"]][0], GameState.position_presets[wave_data["spawn_position"]][1])
	var stop_position = Vector2(GameState.position_presets[wave_data["stop_position"]][0], GameState.position_presets[wave_data["stop_position"]][1])
	var leave_position = Vector2(GameState.position_presets[wave_data["leave_position"]][0], GameState.position_presets[wave_data["leave_position"]][1])
	enemy_path_points = [start_position, stop_position, leave_position]
	spawn_offset = Vector2(GameState.position_presets[wave_data["spawn_offset"]][0], GameState.position_presets[wave_data["spawn_offset"]][1])
	drop_item = wave_data["drop_item"]

func start_spawn_cycle() -> void:
	$SpawnTimer.start(spawn_interval / enemy_count)
	spawn_enemy(wave_enemy_index)

func spawn_enemy(enemy_iterator : int) -> void:
	wave_enemy_index += 1
	var enemy_path = Path2D.new()
	var enemy_path_follower = PathFollow2D.new()
	enemy_path_follower.rotates = false
	enemy_path.curve = Curve2D.new()
	enemy_path.add_child(enemy_path_follower)
	add_child(enemy_path)
	var point_index = 0
	remaining_enemy_count -= 1
	for point in enemy_path_points:
		if point_index == 2:
			var in_vector = Vector2(192.0 - point.x, 0.0)
			enemy_path.curve.add_point(point + enemy_iterator * spawn_offset, in_vector)
		else:
			enemy_path.curve.add_point(point + enemy_iterator * spawn_offset)
		if point_index == 1:
			enemy_path_follower.set_progress_ratio(1.0)
			distance_to_stop_point = enemy_path_follower.progress
			enemy_path_follower.set_progress_ratio(0.0)
		point_index += 1
			
	var new_enemy_instance = enemy_scene.instantiate()
	new_enemy_instance.distance_to_stop_point = distance_to_stop_point
	new_enemy_instance.set_enemy_name(enemy_name)
	new_enemy_instance.set_drop_item(drop_item)
	new_enemy_instance.set_fire_while_moving(fire_while_moving)
	new_enemy_instance.add_to_group("enemies")
	enemy_path_follower.add_child(new_enemy_instance)

func pause(value : bool) -> void:
	$SpawnTimer.paused = value

func _on_spawn_timer_timeout():
	if remaining_enemy_count > 0:
		start_spawn_cycle()
	else:
		finished_spawning = true
