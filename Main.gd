extends Node

var title_screen_instance
var game_screen_instance

# 
func _ready():
	SignalBus.menu_command.connect(_menu_actioned)
	load_title_scene()

func _process(delta):
	pass

# Loads in the title screen scene
func load_title_scene() -> void:
	var title_screen = load("res://game/TitleScreen.tscn")
	title_screen_instance = title_screen.instantiate()
	add_child(title_screen_instance)

# Receives menu actions and runs functions based on the command
# "NewGame" command behaves differently if title screen scene is loaded
func _menu_actioned(command : String) -> void:
	if command == "NewGame":
		if title_screen_instance in get_children():
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
	title_screen_instance.queue_free()
	var game_screen = load("res://game/game_screen.tscn")
	game_screen_instance = game_screen.instantiate()
	add_child(game_screen_instance)

# Loads the options scene
func show_options() -> void:
	pass

# Closes the game
func quit_game() -> void:
	pass

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


