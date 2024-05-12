extends Control

var game_field_instance
var interface_instance


func _ready():
	start_game()

func _process(delta):
	pass

func start_game():
	var game_field = load("res://game/game_field_container.tscn")
	game_field_instance = game_field.instantiate()
	$MarginContainer/HSplitContainer.add_child(game_field_instance)
	var interface = load("res://game/interface.tscn")
	interface_instance = interface.instantiate()
	$MarginContainer/HSplitContainer.add_child(interface_instance)

func _on_boss_spawn_timer_timeout():
	$Boss.start($BossStartPosition.position)

func _on_start_timer_timeout():
	$Player.start($PlayerStartPosition.position)
	$BossSpawnTimer.start()
	$BossMovementTimer.start()

func game_over():
	# TODO Destroy the rigidbody2D that collided
	# TODO $Music.stop()
	# TODO $DeathSound.play()
	$BossAttackTimer.stop()
	$BossMovementTimer.stop()
	$HUD.show_game_over()
	get_tree().call_group("bullets", "_zero_velocity")
