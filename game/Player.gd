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

# Called when the node enters the scene tree for the first time.
func _ready():
	screen_size = get_viewport_rect().size
	$Body.play("idle")
	start()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	UpdatePosition()
	manage_options()
	# Rotate the hitbox
	direction += PI/180
	$HitBox.set_rotation(direction)
	get_tree().call_group("option", "set_rotation", direction)
	var velocity = Vector2.ZERO # The player's movement vector
	if $PlayerHitBox.is_disabled():
		$Body.self_modulate.a = 0.1 if Engine.get_frames_drawn() % 3 in [0, 1] else 1.0
	else:
		$Body.self_modulate.a = 1.0
	if $DeathTimer.time_left > 0:
		$DeathAnimation.show()
		$DeathAnimation.self_modulate = $DeathAnimation.self_modulate.lerp(Color(1,1,1,0), .1)
		$DeathAnimation.scale += $DeathAnimation.scale * .1
	else:
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
	if Engine.get_frames_drawn() % 4 == 0:
		for option in get_tree().get_nodes_in_group("option"):
			var shot = playershot_scene.instantiate()
			shot.position = GameState.player_position + option.position + Vector2(0.0, -16.0)
			shot.top_level = true
			option.add_child(shot)

func _on_body_entered(body):
	if "item_type" in body:
		if body.magnetized:
			get_item(body.item_type)
			body.queue_free()
		body.set_magnetize(true)
	else:
		$PlayerHitBox.set_deferred("disabled", true)
		$DeathTimer.start()
		$Body.hide() # Player disappears after being hit.
		get_tree().call_group("option", "hide")
		GameState.player_lives -= 1
		if GameState.player_lives <= 0:
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
	get_tree().call_group("option", "show")

func UpdatePosition() -> void:
	GameState.player_position = position

func _on_start_timer_timeout():
	$PlayerHitBox.set_deferred("disabled", false)

func _on_death_timer_timeout():
	if GameState.player_lives >= 1:
		start()

func get_item(item_type : String) -> void:
	if item_type == "large_power":
		GameState.player_power += 50
		GameState.player_power = clamp(GameState.player_power, 0, 255)
	elif item_type == "small_power":
		GameState.player_power += 10
		GameState.player_power = clamp(GameState.player_power, 0, 255)
	elif item_type == "point":
		GameState.points += 10000 * GameState.player_graze
	elif item_type == "full_power":
		GameState.player_power == 255
	elif item_type == "bomb":
		GameState.player_bombs += 1
	elif item_type == "life":
		GameState.player_lives += 1

func manage_options() -> void:
	var calculated_options = (1 + GameState.player_power / 80)
	var current_options = get_tree().get_node_count_in_group("option")
	if current_options != calculated_options:	
		get_tree().call_group("option", "queue_free")
		for i in range(calculated_options):
			var option_texture = load("res://art/option.tres")
			var option_body = Sprite2D.new()
			option_body.set_texture(option_texture)
			var x
			var y
			if calculated_options % 2 == 0:
				x = (i - calculated_options / 2.0) * 15
				y = -abs(i - (0.5 + calculated_options / 4)) * 15
			else:
				x = (i - calculated_options / 2.0) * 15
				y = -abs(i - (1 + calculated_options / 4)) * 15
			option_body.position = Vector2(8.0 + x, -y - 40)
			option_body.add_to_group("option")
			add_child(option_body)
