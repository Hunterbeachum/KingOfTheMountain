extends Node
signal boss_movement
signal player_location
var player_position : Vector2 = Vector2(0.0, 0.0)
var title_screen_instance
var game_screen_instance

func _ready():
	var title_screen = load("res://game/TitleScreen.tscn")
	title_screen_instance = title_screen.instantiate()
	add_child(title_screen_instance)

func _process(delta):
	pass

# Starts a new game from the title screen.
# Deletes the title screen, and loads a new game_screen scene.
func new_game():
	# game window 384x448
	# global_position 32,16
	title_screen_instance.queue_free()
	var game_screen = load("res://game/game_screen.tscn")
	game_screen_instance = game_screen.instantiate()
	add_child(game_screen_instance)

func game_over():
	# TODO $Music.stop() and $Music.play() gameover.wav
	# TODO Bullettime all moving bodies on screen (see bullet.gd._zero_velocity())
	# TODO Instantiate game over options scene (retry, quit to title)
	$BossAttackTimer.stop()
	$BossMovementTimer.stop()
	$HUD.show_game_over()
	get_tree().call_group("bullets", "_zero_velocity")


