extends Control

var game_field_instance
var interface_instance

func _ready():
	GameState.player_lives = GameState.STARTING_LIVES
	GameState.player_bombs = GameState.STARTING_BOMBS
	var game_field = load("res://game/game_field_container.tscn")
	game_field_instance = game_field.instantiate()
	$MarginContainer/HSplitContainer.add_child(game_field_instance)
	var interface = load("res://game/interface.tscn")
	interface_instance = interface.instantiate()
	$MarginContainer/HSplitContainer.add_child(interface_instance)
	var test = game_field_instance.get_children()[0].get_children()
	game_field_instance.get_node("GameField/Player").connect("hit", interface_instance.update_lives)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func start_game():
	pass

func _on_boss_spawn_timer_timeout():
	$Boss.start($BossStartPosition.position)

func _on_start_timer_timeout():
	$Player.start($PlayerStartPosition.position)
	$BossSpawnTimer.start()
	$BossMovementTimer.start()


func game_over():
	# TODO figure out why everything is slowing down
	# TODO Destroy the rigidbody2D that collided
	# TODO $Music.stop()
	# TODO $DeathSound.play()
	$BossAttackTimer.stop()
	$BossMovementTimer.stop()
	$HUD.show_game_over()
	get_tree().call_group("bullets", "_zero_velocity")
