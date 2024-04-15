extends Node
signal boss_movement
signal player_location
var boss_movement_location
@export var bullet_scene: PackedScene

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_tree().call_group("bullets", "_update_linear_velocity", $Player.position)
	pass

func new_game():
	get_tree().call_group("bullets", "queue_free")
	$StartTimer.start()


func _on_boss_spawn_timer_timeout():
	$Boss.start($BossStartPosition.position)


func _on_boss_attack_timer_timeout():
	get_tree().call_group("bullets", "_update_bullet_lifespan")
	var bullet_spawn_location = $Boss.position
	var direction = bullet_spawn_location.angle_to_point($Player.position)
	var direction_list = []
	for n in range(5):
		direction_list.append(direction + (n - 2) * PI/15)
	for n in direction_list:
		var bullet = bullet_scene.instantiate()
		var bullet_velocity = Vector2(100.0, 0.0)
		bullet.position = bullet_spawn_location
		bullet.linear_velocity = bullet_velocity.rotated(n)
		add_child(bullet)


func _on_start_timer_timeout():
	$Player.start($PlayerStartPosition.position)
	$BossSpawnTimer.start()
	$BossMovementTimer.start()
	$BossAttackTimer.start()



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


