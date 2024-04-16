extends RigidBody2D
var destination
@export var bullet_scene: PackedScene
# Called when the node enters the scene tree for the first time.
func _ready():
	hide()
	$BossBody.play("aya")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if destination != null:
		if position.distance_to(destination) < 10:
			linear_velocity = Vector2(0.0, 0)
	# Manage animation based on x velocity
	# x == 0 = reverse from L/R animation then idle
	if linear_velocity.x == 0:
		if $BossBody.animation == "aya_start_move" and $BossBody.frame == 0:
			$BossBody.animation = "aya"
		elif $BossBody.animation == "aya_start_move":
			$BossBody.play_backwards("aya_start_move")
		elif $BossBody.animation == "aya_move" and $BossBody.frame == 0:
			$BossBody.play_backwards("aya_start_move")
		elif $BossBody.animation == "aya_move":
			$BossBody.play_backwards("aya_move")
	else:
		if $BossBody.animation == "aya":
			$BossBody.play("aya_start_move")
		elif $BossBody.animation == "aya_start_move" and $BossBody.frame == 1:
			$BossBody.play("aya_move")
	if linear_velocity.x > 0:
		$BossBody.set_flip_h(true)
	elif linear_velocity.x < 0 or $BossBody.animation == "aya":
		$BossBody.set_flip_h(false)



func start(pos):
	position = pos
	show()
	$CollisionShape2D.disabled = false


func _on_main_boss_movement(pos):
	destination = pos
	var direction = position.angle_to_point(pos)
	linear_velocity = Vector2(200.0, 0.0).rotated(direction)


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
