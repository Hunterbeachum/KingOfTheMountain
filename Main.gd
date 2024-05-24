extends Node

var title_screen_instance
var game_screen_instance
var pause_menu_instance

# 
func _ready():
	SignalBus.quit.connect(quit_game)
	SignalBus.pause.connect(toggle_pause_menu)
	SignalBus.menu_command.connect(_menu_actioned)
	load_title_scene()

func _process(delta):
	pass

# Loads in the title screen scene
func load_title_scene() -> void:
	var title_screen = load("res://game/TitleScreen.tscn")
	title_screen_instance = title_screen.instantiate()
	add_child(title_screen_instance)

func toggle_pause_menu(is_game_over : bool) -> void:
	if is_instance_valid(pause_menu_instance):
		pause_menu_instance.queue_free()
		get_tree().paused = false
	else:
		get_tree().paused = true
		var pause_menu = load("res://game/pause_menu.tscn")
		pause_menu_instance = pause_menu.instantiate()
		pause_menu_instance.game_over = is_game_over
		add_child(pause_menu_instance)

# Receives menu actions and runs functions based on the command
# "NewGame" command behaves differently if title screen scene is loaded
func _menu_actioned(command : String) -> void:
	if command == "NewGame":
		if get_tree().paused:
			get_tree().paused = false
		if is_instance_valid(title_screen_instance):
			if title_screen_instance.fading_in:
				title_screen_instance.close()
			else:
				start_new_game()
		else:
			start_new_game()
	if command == "Options":
		show_options()
	if command == "Quit":
		quit_game()

# Starts a new game from the title screen.
# Deletes the title scene, and loads a new game_screen scene.
func start_new_game() -> void:
	if is_instance_valid(pause_menu_instance):
		pause_menu_instance.queue_free()
	if is_instance_valid(title_screen_instance):
		title_screen_instance.queue_free()
	if is_instance_valid(game_screen_instance):
		game_screen_instance.queue_free()
	var game_screen = load("res://game/game_screen.tscn")
	game_screen_instance = game_screen.instantiate()
	add_child(game_screen_instance)

# Loads the options scene
func show_options() -> void:
	pass

# Closes the game
func quit_game() -> void:
	get_tree().quit()

# Stops the game, loads the game over menu
# TODO should this be here?
func game_over() -> void:
	# TODO $Music.stop() and $Music.play() gameover.wav
	# TODO Bullettime all moving bodies on screen (see bullet.gd._zero_velocity())
	# TODO Instantiate game over options scene (retry, quit to title)
	$BossAttackTimer.stop()
	$BossMovementTimer.stop()
	$HUD.show_game_over()
	get_tree().call_group("bullets", "_zero_velocity")


