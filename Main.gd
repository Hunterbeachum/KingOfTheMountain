extends Node
signal boss_movement
signal player_location
var boss_movement_location
var title_screen_instance
var game_screen_instance

# Called when the node enters the scene tree for the first time.
func _ready():
	var title_screen = load("res://game/TitleScreen.tscn")
	title_screen_instance = title_screen.instantiate()
	add_child(title_screen_instance)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func new_game():
	# game window 384x448
	# position 32,16
	title_screen_instance.queue_free()
	var game_screen = load("res://game/game_screen.tscn")
	game_screen_instance = game_screen.instantiate()
	add_child(game_screen_instance)

func _on_start_timer_timeout():
	$Player.start($PlayerStartPosition.position)
	$BossSpawnTimer.start()
	$BossMovementTimer.start()

func _on_boss_movement_timer_timeout():
	boss_movement_location = $BossPath/BossMovementLocation
	boss_movement_location.progress_ratio = randf()
	while boss_movement_location.position.distance_to($Boss.position) < 100:
		boss_movement_location = $BossPath/BossMovementLocation
		boss_movement_location.progress_ratio = randf()
	boss_movement.emit(boss_movement_location.position)


func game_over():
	# TODO figure out why everything is slowing down
	# TODO Destroy the rigidbody2D that collided
	# TODO $Music.stop()
	# TODO $DeathSound.play()
	$BossAttackTimer.stop()
	$BossMovementTimer.stop()
	$HUD.show_game_over()
	get_tree().call_group("bullets", "_zero_velocity")


