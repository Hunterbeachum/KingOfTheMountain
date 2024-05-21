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
@export var enemy_wave_handler : PackedScene

# Sets player lives to 3 and loads in the stage data
func _ready():
	SignalBus.game_over.connect(game_over)
	SignalBus.node_added_to_scene.connect(add_child)
	GameState.player_lives = 3
	load_stage(current_stage)

# Checks the queues each frame
# Pops and runs the relevant function if the time requirement (x_queue[0][0]) is met
func _process(delta):
	time_elapsed = stage_data["stage_duration"] - $StageTimer.get_time_left()
	if not spawn_queue.is_empty():
		if time_elapsed > spawn_queue[0][0]:
			spawn_wave(spawn_queue.pop_front())
	if not camera_queue.is_empty():
		if time_elapsed > camera_queue[0][0]:
			alter_camera(camera_queue.pop_front())
	if not scroll_queue.is_empty():
		if time_elapsed > scroll_queue[0][0]:
			alter_scroll(scroll_queue.pop_front())
	pass

# Converts the stage data from data.json[stage][stage_name] to a dictionary variable
# From that variable, generates queues for enemy spawning and camera controls.
# Creates the 3d background instance
# Creates the player instance
# Starts the stage timer
func load_stage(stage_name : String):
	update_current_stage()
	stage_data = GameState.data["stage"][stage_name]
	for wave in stage_data["stage_enemy_layout"].keys():
		var spawn_time = stage_data["stage_enemy_layout"][wave]["spawn_time"]
		spawn_queue.append([spawn_time, wave])
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

# Creates an enemy_wave_handler child and passes on the wave data
func spawn_wave(wave : Array) -> void:
	var new_enemy_wave_handler = enemy_wave_handler.instantiate()
	new_enemy_wave_handler.wave_data = GameState.data["enemy_wave"][wave[1]]
	add_child(new_enemy_wave_handler)

func alter_camera(tilt_command : Array) -> void:
	background_instance.set_tilt(tilt_command[1])

func alter_scroll(scroll_command : Array) -> void:
	background_instance.set_scroll(scroll_command[1])

func game_over() -> void:
	get_tree().call_group("bullets", "pause")
#	get_viewport().gui_focus_changed.connect(_on_focus_changed)
#	configure_focus()
