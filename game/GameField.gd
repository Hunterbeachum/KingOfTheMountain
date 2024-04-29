extends SubViewport

var current_stage : String = "stage_1"
var stage_data : Dictionary
var spawn_queue : Array = []
var camera_queue : Array = []
var scroll_queue : Array = []
var time_elapsed : float
var next_item
var enemy_instance
var player_instance
var boss_instance
var background_instance


func _ready():
	GameState.player_lives = 3
	load_stage(current_stage)

func _process(delta):
	time_elapsed = stage_data["stage_duration"] - $StageTimer.get_time_left()
	if not spawn_queue.is_empty():
		if time_elapsed > spawn_queue[0][1]:
			spawn_wave(spawn_queue.pop_front())
	if not camera_queue.is_empty():
		if time_elapsed > camera_queue[0][0]:
			alter_camera(camera_queue.pop_front())
	if not scroll_queue.is_empty():
		if time_elapsed > scroll_queue[0][0]:
			alter_scroll(scroll_queue.pop_front())
	pass

func load_stage(stage_name : String):
	update_current_stage()
	stage_data = GameState.data["stage"][stage_name]
	for wave in stage_data["stage_enemy_layout"].keys():
		var spawn_time = stage_data["stage_enemy_layout"][wave]["spawn_time"]
		var spawn_interval = stage_data["stage_enemy_layout"][wave]["spawn_interval"]
		spawn_queue.append([wave, spawn_time, spawn_interval])
	for command in stage_data["stage_camera_commands"]:
		camera_queue.append(command)
	for command in stage_data["stage_scroll_commands"]:
		scroll_queue.append(command)
	var bg = load("res://game/3_dbg.tscn")
	background_instance = bg.instantiate()
	add_child(background_instance)
	var player = load("res://game/player.tscn")
	player_instance = player.instantiate()
	add_child(player_instance)
	$StageTimer.start(stage_data["stage_duration"])

func update_current_stage() -> void:
	GameState.current_stage = current_stage

func spawn_wave(wave : Array) -> void:
	var wave_data = GameState.data["enemy_wave"][wave[0]]
	var enemy_count = wave_data["enemy_count"]
	var spawn_interval = wave[2]
	var enemy_name = wave_data["enemy_name"]
	var spawn_position = Vector2(wave_data["spawn_position"][0], wave_data["spawn_position"][1])
	var stop_position = Vector2(wave_data["stop_position"][0], wave_data["stop_position"][1])
	var leave_position = Vector2(wave_data["leave_position"][0], wave_data["leave_position"][1])
	var spawn_offset = Vector2(wave_data["spawn_offset"][0], wave_data["spawn_offset"][1])
	var drop_item = wave_data["drop_item"]
	spawn_enemy(enemy_name, 0, spawn_position, stop_position, leave_position, spawn_offset, drop_item)
	for i in range(enemy_count - 1):
		await get_tree().create_timer(spawn_interval / enemy_count).timeout
		spawn_enemy(enemy_name, (i + 1), spawn_position, stop_position, leave_position, spawn_offset, drop_item)

func spawn_enemy(enemy_name : String, i : int, spawn_position : Vector2, stop_position : Vector2, leave_position : Vector2, spawn_offset : Vector2, drop_item : String) -> void:
	var enemy = load("res://game/fairy.tscn")
	enemy_instance = enemy.instantiate()
	enemy_instance.position = spawn_position + i * spawn_offset
	enemy_instance.set_enemy_name(enemy_name)
	enemy_instance.set_stop_position(stop_position + i * spawn_offset)
	enemy_instance.set_leave_position(leave_position + i * spawn_offset)
	enemy_instance.set_drop_item(drop_item)
	add_child(enemy_instance)

func alter_camera(tilt_command : Array) -> void:
	background_instance.set_tilt(tilt_command[1])

func alter_scroll(scroll_command : Array) -> void:
	background_instance.set_scroll(scroll_command[1])

func game_over():
	get_tree().call_group("bullets", "_zero_velocity")
