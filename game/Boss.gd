extends RigidBody2D
var destination
var current_pattern = ""
@export var bullet_handler: PackedScene
# Called when the node enters the scene tree for the first time.


func _ready():
	$BossBody.play("aya")
	start($BossStartPosition.position)
	$BossAttackTimer.start()
	$BossMovementTimer.start()
	pass

func _on_boss_start_timer_timeout():
	start($BossStartPosition.position)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	UpdatePosition()
	if destination != null:
		if position.distance_to(destination.position) < 10:
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
	$BossHitbox.disabled = false


func _boss_movement():
	var direction = position.angle_to_point(destination.position)
	linear_velocity = Vector2(200.0, 0.0).rotated(direction)
	$BossMovementTimer.start(5.0)


func _on_boss_attack_timer_timeout():
	# TODO current_pattern = pattern_list.next()?
	current_pattern = "test_pattern_1"
	UpdatePattern()
	var new_bullet_handler = bullet_handler.instantiate()
	add_child(new_bullet_handler)
	

func UpdatePattern() -> void:
	GameState.current_pattern = current_pattern

func _on_boss_movement_timer_timeout():
	if GameState.drawing_pattern:
		$BossMovementTimer.start(1.0)
	else:
		destination = $BossPath/BossMovementLocation
		destination.progress_ratio = randf()
		while destination.position.distance_to(position) < 50:
			destination = $BossPath/BossMovementLocation
			destination.progress_ratio = randf()
		_boss_movement()

func UpdatePosition() -> void:
	GameState.boss_position = position
