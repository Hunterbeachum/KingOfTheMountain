extends Area2D
signal hit
signal gameover

@export var playershot_scene: PackedScene
@export var speed = 200
var loading_in : bool = false
var screen_size
var direction = 0
var current_modulate
var opacity = 0.0
var lives : int

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	$Body.play("idle")
	start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	UpdatePosition()
	# Rotate the hitbox
	direction += PI/180
	$HitBox.rotation = direction
	var velocity = Vector2.ZERO # The player's movement vector
	if $PlayerHitBox.is_disabled():
		$Body.self_modulate.a = 0.1 if Engine.get_frames_drawn() % 3 in [0, 1] else 1.0
	else:
		$Body.self_modulate.a = 1.0
	if $DeathTimer.time_left > 0:
		$DeathAnimation.show()
		$DeathAnimation.self_modulate = $DeathAnimation.self_modulate.lerp(Color(1,1,1,0), .1)
		$DeathAnimation.scale += $DeathAnimation.scale * .1
	if Input.is_action_pressed("move_right"):
		velocity.x += 1
	if Input.is_action_pressed("move_left"):
		velocity.x -= 1	
	if Input.is_action_pressed("move_down"):
		velocity.y += 1
	if Input.is_action_pressed("move_up"):
		velocity.y -= 1
	
	if Input.is_action_pressed("focus"):
		speed = 100
		opacity += .1
		opacity = clamp(opacity, 0, 1)
		$HitBox.set_self_modulate(Color(1, 1, 1, opacity))
	else:
		speed = 200
		opacity -= .1
		opacity = clamp(opacity, 0, 1)
		$HitBox.set_self_modulate(Color(1, 1, 1, opacity))
	
	if Input.is_action_pressed("confirm"):
		fire()
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)
	if $StartTimer.time_left > 1.75:
		position = position.lerp($PlayerStartPosition.position, .1)
	# Manage animation based on x velocity
	# x == 0 = reverse from L/R animation then idle
	if velocity.x == 0:
		if $Body.animation == "start_right" and $Body.frame == 0:
			$Body.animation = "idle"
		elif $Body.animation == "move_right":
			$Body.play_backwards("start_right")
		elif $Body.animation == "start_left" and $Body.frame == 0:
			$Body.animation = "idle"
		elif $Body.animation == "move_left":
			$Body.play_backwards("start_left")
	# x > 0 = begin R animation then loop R lean 
	elif velocity.x > 0:
		if $Body.animation == "start_right" and $Body.frame == 3:
			$Body.animation = "move_right"
		elif $Body.animation != "move_right":
			$Body.play("start_right")
	# x < 0 = begin L animation then loop L lean
	elif velocity.x < 0:
		if $Body.animation == "start_left" and $Body.frame == 3:
			$Body.animation = "move_left"
		elif $Body.animation != "move_left":
			$Body.play("start_left")
	

func fire() -> void:
	var shot = playershot_scene.instantiate()
	shot.linear_velocity = Vector2(0.0, -500.0)
	add_child(shot)

func _on_body_entered(body):
	$PlayerHitBox.set_deferred("disabled", true)
	$DeathTimer.start()
	$Body.hide() # Player disappears after being hit.
	lives -= 1
	if lives <= 0:
		gameover.emit()
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.

func start() -> void:
	$PlayerHitBox.disabled = true
	$DeathAnimation.hide()
	$DeathAnimation.scale = Vector2.ONE
	$DeathAnimation.self_modulate = Color(1,1,1,1)
	$StartTimer.start()
	position = Vector2(180.0, 500.0)
	$Body.show()

func UpdatePosition() -> void:
	GameState.player_position = position

func _on_start_timer_timeout():
	$PlayerHitBox.set_deferred("disabled", false)

func _on_death_timer_timeout():
	start()
