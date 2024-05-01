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

func _ready():
	screen_size = get_viewport_rect().size
	$Body.play("idle")
	start()

func _process(delta):
	update_position()
	manage_options()
	# Rotate the hitbox sprite and the option sprites
	direction += PI/180
	$HitBox.set_rotation(direction)
	get_tree().call_group("option", "set_rotation", direction)
	var velocity = Vector2.ZERO # The player's movement vector
	# Blink the player if they are current immune (collision disabled) else set opacity to full
	if $PlayerHitBox.is_disabled():
		$Body.self_modulate.a = 0.1 if Engine.get_frames_drawn() % 3 in [0, 1] else 1.0
	else:
		$Body.self_modulate.a = 1.0
	# Play death animation if death timer is running, an animate it
	if $DeathTimer.time_left > 0:
		$DeathAnimation.show()
		$DeathAnimation.self_modulate = $DeathAnimation.self_modulate.lerp(Color(1,1,1,0), .1)
		$DeathAnimation.scale += $DeathAnimation.scale * .1
	else:
		# Handle movement input
		if Input.is_action_pressed("move_right"):
			velocity.x += 1
		if Input.is_action_pressed("move_left"):
			velocity.x -= 1	
		if Input.is_action_pressed("move_down"):
			velocity.y += 1
		if Input.is_action_pressed("move_up"):
			velocity.y -= 1
		
		# Handle focus input (fade in hitbox visible, slow movement by 50%)
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
		
		# Handle attack input
		if Input.is_action_pressed("confirm"):
			fire()
		
		# Normalize velocity so diagonal movement isn't 2x speed
		# Then move player according to input and limit player to the game_screen size
		if velocity.length() > 0:
			velocity = velocity.normalized() * speed
		position += velocity * delta
		position = position.clamp(Vector2.ZERO, screen_size)
		
		# Player load-in - automove toward the default starting position
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

# Runs when 'confirm' input is pressed.
# Every 4 frames it creates a playershot node for each option.
func fire() -> void:
	if Engine.get_frames_drawn() % 4 == 0:
		for option in get_tree().get_nodes_in_group("option"):
			var shot = playershot_scene.instantiate()
			shot.position = GameState.player_position + option.position + Vector2(0.0, -16.0)
			shot.top_level = true
			option.add_child(shot)

# Runs when player node scans another collisionshape overlapping PlayerHitBox
# Player node only scans layers set on its mask in the inspector.
# Current set to 3 (enemies), 4 (bullets), 5 (items).
# If the body is an item, it activates the item's magnetics (then collides again with a second pickup collision)
# If the body is a bullet or an enemy, the player is hit and loses a life before respawning (if lives > 0).
# If the players lives <= 0, starts the gameover function in main? could be better elsewhere (TODO)
func _on_body_entered(body):
	if "item_type" in body:
		if body.magnetized:
			get_item(body.item_type)
			body.queue_free()
		body.set_magnetize(true)
	else:
		# Must be deferred as we can't change physics properties on a physics callback.
		$PlayerHitBox.set_deferred("disabled", true)
		$DeathTimer.start()
		$Body.hide() # Player disappears after being hit.
		get_tree().call_group("option", "hide")
		GameState.player_lives -= 1
		if GameState.player_lives <= 0:
			gameover.emit()
		# TODO $DeathSound.play()
		hit.emit()

# Loads player in from off-screen, granting temporary invincibility
func start() -> void:
	$PlayerHitBox.disabled = true
	$DeathAnimation.hide()
	$DeathAnimation.scale = Vector2.ONE
	$DeathAnimation.self_modulate = Color(1,1,1,1)
	$StartTimer.start()
	position = Vector2(180.0, 500.0)
	$Body.show()
	get_tree().call_group("option", "show")
	GameState.player_power = 255

func update_position() -> void:
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

# Loads player options if not loaded, or updates their count if more are loaded than appropriate.
# Options are bits that spawn around the player to serve as an indication of the player's current power
# and the positional source of the player's attacks.
func manage_options() -> void:
	var calculated_options = (1 + GameState.player_power / 80)
	var current_options = get_tree().get_node_count_in_group("option")
	if current_options != calculated_options:	
		get_tree().call_group("option", "queue_free")
		for i in range(calculated_options):
			var option_texture = load("res://art/option.tres")
			var option_body = Sprite2D.new()
			option_body.set_texture(option_texture)
			var x = 7.5 + (i - calculated_options / 2.0) * 15
			var y = abs(x) - 40
			option_body.position = Vector2(x, y)
			option_body.add_to_group("option")
			add_child(option_body)
