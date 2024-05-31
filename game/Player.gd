extends Area2D

var particles : GPUParticles2D
@export var particles_scene : PackedScene
@export var playershot_scene : PackedScene
@export var shield_scene : PackedScene
@export var speed = 200
var burst_hit_box_instance : CollisionShape2D
var shield_instance : Sprite2D
var screen_size : Vector2
var direction = 0
var opacity = 0.0

func _ready():
	GameState.player_lives = GameState.STARTING_LIVES
	GameState.player_bombs = GameState.STARTING_BOMBS
	SignalBus.update_ui.emit()
	SignalBus.shield_burst.connect(start_shield_burst)
	screen_size = get_viewport_rect().size
	$Body.play("idle")
	instantiate_shield()
	start()

func instantiate_shield() -> void:
	shield_instance = shield_scene.instantiate()
	add_child(shield_instance)

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		SignalBus.pause.emit(false)
	update_position()
	manage_options()
	rotate_children()
	var velocity = Vector2.ZERO # The player's movement vector
	flash_if_immune()
	# Play death animation if death timer is running, an animate it
	if $DeathTimer.time_left > 0:
		play_death_animation()
	else:
		shield_burst()
		# Handle movement input
		shield()
		shield_instance.cast_shield(delta, true)
		velocity += handle_movement_input()
		# Normalize velocity so diagonal movement isn't 2x speed
		if velocity.length() > 0:
			velocity = velocity.normalized() * speed
		# Handle focus input (fade in hitbox visible, slow movement by 50%)
		if Input.is_action_pressed("focus"):
			focus(true)
		else:
			focus(false)
		if Input.is_action_pressed("shield"):
			shield_instance.deploy_shield()
		if Input.is_action_pressed("confirm"):
			fire()
		# Handle player movement
		player_movement(velocity, delta)
		# Player load-in - automove toward the default starting position
		if $StartTimer.time_left > 1.75:
			position = position.lerp($PlayerStartPosition.position, .1)
		# Handle player animation
		play_animation(velocity)
		if position.y < 148:
			magnetize_all_items()

# Handle movement input
func handle_movement_input() -> Vector2:
	var vector_sum = Vector2.ZERO
	if Input.is_action_pressed("move_right"):
		vector_sum += Vector2(1.0, 0.0)
	if Input.is_action_pressed("move_left"):
		vector_sum += Vector2(-1.0, 0.0)
	if Input.is_action_pressed("move_down"):
		vector_sum += Vector2(0.0, 1.0)
	if Input.is_action_pressed("move_up"):
		vector_sum += Vector2(0.0, -1.0)
	return vector_sum

# Move player according to input and limit player to the game_screen size
func player_movement(velocity : Vector2, delta : float) -> void:
	position += velocity * delta
	position = position.clamp(Vector2.ZERO, screen_size)

# Manage animation based on x velocity
# x == 0 = reverse from L/R animation then idle
func play_animation(velocity : Vector2) -> void:
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

# Handle focus input (fade in hitbox visible, slow movement by 50%)
func focus(is_focused : bool) -> void:
	if is_focused:
		speed = 100
		opacity += .1
		opacity = clamp(opacity, 0, 1)
		$HitBox.set_self_modulate(Color(1, 1, 1, opacity))
	else:
		speed = 200
		opacity -= .1
		opacity = clamp(opacity, 0, 1)
		$HitBox.set_self_modulate(Color(1, 1, 1, opacity))

# Displays player shield, enables shield hitbox
func shield() -> void:
	if shield_instance.shield_active:
		$ShieldHitBox.set_deferred("disabled", false)
	else:
		$ShieldHitBox.set_deferred("disabled", true)

func shield_burst() -> void:
	if not $BurstTimer.is_stopped():
		if not is_instance_valid(burst_hit_box_instance):
			burst_hit_box_instance = CollisionShape2D.new()
			var burst_hit_box_shape = CircleShape2D.new()
			burst_hit_box_shape.radius = 32.0
			burst_hit_box_instance.shape = burst_hit_box_shape
			add_child(burst_hit_box_instance)
		burst_hit_box_instance.scale = Vector2(4.0 - (6 * $BurstTimer.time_left), 4.0 - (6 * $BurstTimer.time_left))
	else:
		if is_instance_valid(burst_hit_box_instance):
			burst_hit_box_instance.queue_free()

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
# Currently set to 3 (enemies), 4 (bullets), 5 (items).
func _on_body_entered(body):
	if body.collision_name == "item":
		collect_item(body)
	elif body.collision_name == "bullet":
		if not $ShieldHitBox.disabled or is_instance_valid(burst_hit_box_instance):
			absorb_bullet(body)
		elif not body.grazed:
			body.graze()
			graze()
		else:
			player_death(body)

# If the body is an item, it activates the item's magnetics (then collides again with a second pickup collision)
func collect_item(body) -> void:
	if body.magnetized:
		get_item(body.item_type)
		body.queue_free()
	else:
		body.set_magnetize(true)

func absorb_bullet(body) -> void:
	if body.collision_name == "bullet":
		body.disappearing = true
		body.generate_particles()
		shield_instance.shield_stagger += 100 if $BurstTimer.is_stopped() else 0
	if body.collision_name == "enemy":
		shield_instance.shield_stagger += 10 if $BurstTimer.is_stopped() else 0

func graze():
	shield_instance.shield_charge_bar.set_value_no_signal(shield_instance.shield_charge_bar.value + 100)
	var particles_instance = particles_scene.instantiate()
	add_child(particles_instance)
	particles_instance.emitting = true
	particles_instance.add_to_group("player_particles")

func start_shield_burst() -> void:
	$BurstTimer.start()

# If the body is a bullet or an enemy, the player is hit and loses a life before respawning (if lives > 0).
# If the players lives <= 0, starts the gameover function in main? could be better elsewhere (TODO)
func player_death(body) -> void:
	# Must be deferred as we can't change physics properties on a physics callback.
	if $DeathTimer.is_stopped() and $StartTimer.is_stopped():
	#	$PlayerHitBox.set_deferred("disabled", true)
		particles = particles_scene.instantiate()
		add_child(particles)
		particles.emitting = true
		particles.add_to_group("player_particles")
		$DeathTimer.start()
		$Body.hide() # Player disappears after being hit.
		get_tree().call_group("option", "hide")
		GameState.player_lives = clamp((GameState.player_lives - 1), 0, 8)
		if GameState.player_lives <= 0:
			SignalBus.game_over.emit()
			queue_free()
		else:
			get_tree().call_group("bullets", "disappear")
		SignalBus.player_hit.emit()

# Animates the death sprite by expanding it and reducing the alpha
func play_death_animation() -> void:
	$DeathAnimation.show()
	$DeathAnimation.self_modulate = $DeathAnimation.self_modulate.lerp(Color(1,1,1,0), .1)
	$DeathAnimation.scale += $DeathAnimation.scale * .1

# Blink the player if they are currently immune (collision disabled) else set opacity to full
func flash_if_immune() -> void:
#	if $PlayerHitBox.is_disabled():
	if not $StartTimer.is_stopped():
		$Body.self_modulate.a = 0.1 if Engine.get_frames_drawn() % 3 in [0, 1] else 1.0
	else:
		$Body.self_modulate.a = 1.0

# Rotate the hitbox sprite and the option sprites
func rotate_children() -> void:
	direction += PI/180
	$HitBox.set_rotation(direction)
	get_tree().call_group("option", "set_rotation", direction)

# Loads player in from off-screen, granting temporary invincibility
func start() -> void:
#	$PlayerHitBox.disabled = true
	$DeathAnimation.hide()
	$DeathAnimation.scale = Vector2.ONE
	$DeathAnimation.self_modulate = Color(1,1,1,1)
	$StartTimer.start()
	position = Vector2(180.0, 500.0)
	$Body.show()
	get_tree().call_group("option", "show")
	GameState.player_bombs = GameState.STARTING_BOMBS
	SignalBus.update_ui.emit()

func update_position() -> void:
	GameState.player_position = position

func _on_start_timer_timeout():
#	$PlayerHitBox.set_deferred("disabled", false)
	get_tree().call_group("player_particles", "queue_free")

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
	SignalBus.update_ui.emit()

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

func magnetize_all_items() -> void:
	get_tree().call_group("items", "set_magnetize", true)
