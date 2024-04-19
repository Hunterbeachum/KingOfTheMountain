extends Area2D
signal hit

@export var speed = 200
var screen_size
var direction = 0
var current_modulate
var opacity = 0.0
@onready var player_vars = get_node("/root/playervariables")

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	start($PlayerStartPosition.position)
	$Body.play("idle")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	UpdatePosition()
	# Rotate the hitbox
	direction += PI/180
	$HitBox.rotation = direction
	var velocity = Vector2.ZERO # The player's movement vector
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
	
	if velocity.length() > 0:
		velocity = velocity.normalized() * speed
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
	
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)


func _on_body_entered(body):
	hide() # Player disappears after being hit.
	hit.emit()
	# Must be deferred as we can't change physics properties on a physics callback.
	$PlayerHitBox.set_deferred("disabled", true)


func start(pos):
	position = pos
	show()
	$PlayerHitBox.disabled = false

func UpdatePosition() -> void:
	GameState.player_position = global_position
