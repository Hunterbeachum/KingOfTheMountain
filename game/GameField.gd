extends SubViewport

var current_stage : String = "stage_1"
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
	load_stage(current_stage)

func _process(delta):
	time_elapsed = GameState.data["stage"][current_stage]["stage_duration"] - $StageTimer.get_time_left()
	if time_elapsed > spawn_queue[0][1]:
		spawn_wave(spawn_queue[0])
	
	pass

func load_stage(stage_name : String):
	update_current_stage()
	for wave in len(GameState.data["stage"][current_stage]["stage_enemy_layout"]):
		spawn_queue.push_back(GameState.data["stage"][current_stage]["stage_enemy_layout"][wave])
	for command in len(GameState.data["stage"][current_stage]["stage_camera_commands"]):
		camera_queue.push_back(GameState.data["stage"][current_stage]["stage_camera_commands"][command])
	for command in len(GameState.data["stage"][current_stage]["stage_scroll_commands"]):
		scroll_queue.push_back(GameState.data["stage"][current_stage]["stage_scroll_commands"][command])
	var bg = load("res://game/3_dbg.tscn")
	background_instance = bg.instantiate()
	add_child(background_instance)
	var player = load("res://game/player.tscn")
	player_instance = player.instantiate()
	add_child(player_instance)
	$StageTimer.start(GameState.data["stage"][current_stage]["stage_duration"])

func update_current_stage() -> void:
	GameState.current_stage = current_stage

func spawn_wave(wave) -> void:
	var enemy_count = GameState["enemy_wave"][wave[0]]["enemy_count"]
	var spawn_interval = wave[2]
	var enemy_name = GameState["enemy_wave"][wave[0]]["enemy_name"]
	var spawn_position = Vector2(GameState["enemy_wave"][wave[0]]["spawn_position"])
	var stop_position = Vector2(GameState["enemy_wave"][wave[0]]["stop_position"])
	var leave_position = Vector2(GameState["enemy_wave"][wave[0]]["leave_position"])
	var spawn_offset = Vector2(GameState["enemy_wave"][wave[0]]["spawn_offset"])
	spawn_enemy(enemy_name, 0, spawn_position, stop_position, leave_position, spawn_offset)
	for i in range(enemy_count - 1):
		await get_tree().create_timer(spawn_interval / enemy_count).timeout
		spawn_enemy(enemy_name, i, spawn_position, stop_position, leave_position, spawn_offset)

func spawn_enemy(enemy_name : String, i : int, spawn_position : Vector2, stop_position : Vector2, leave_position : Vector2, spawn_offset : Vector2) -> void:
	var enemy = load("res://game/fairy.tscn")
	enemy_instance = enemy.instantiate()
	enemy_instance.position = spawn_position + i * spawn_offset
	enemy_instance.set_enemy_name(enemy_name)
	enemy_instance.set_stop_position(stop_position + i * spawn_offset)
	enemy_instance.set_leave_position(leave_position + i * spawn_offset)
	add_child(enemy_instance)
