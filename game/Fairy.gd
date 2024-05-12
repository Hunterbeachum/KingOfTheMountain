extends RigidBody2D
var color : String = ""
var current_destination_index : int = 1
var enemy_name : String = ""
var drop_item : String
var speed : int = 0
var health : int = 100
var pattern_list : Array = []
var death_pattern_list : Array = []
var enemy_gamestate_appended : bool = false
var enemy_index : int
var flashing : bool = false
var dead : bool = false
var enemy_path : Path2D
var enemy_path_follower : PathFollow2D
var moving : bool = true
var on_screen : bool = false
var distance_to_stop_point : float
var fire_while_moving : bool
var previous_frame_x_position : float = 0.0
@export var bullet_handler: PackedScene
@export var item: PackedScene
@export var particles_scene : PackedScene
var particles : GPUParticles2D

func _ready():
	load_enemy()
	start()
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	UpdateEnemyGameState()
	if moving:
		enemy_movement(delta)
	if $EnemyDeathTimer.time_left > 0:
		play_death_animation()
	if health <= 0 and not dead:
		perish()
	if dead and $EnemyDeathTimer.time_left <= 0:
		queue_free()
	if flashing and Engine.get_frames_drawn() % 3 == 0:
		flash()
	else:
		$Body.material.set_shader_parameter("solid_color", Color(1, 1, 1, 0))
	if get_parent().progress > distance_to_stop_point and not fire_while_moving:
		moving = false
		distance_to_stop_point = 9999
		current_destination_index += 1
	if (current_destination_index > 1 or fire_while_moving) and on_screen:
		for pattern in pattern_list:
			play_pattern(pattern_list.pop_front())
	play_animation()

func start() -> void:
	show()
	previous_frame_x_position = get_parent().global_position.x
	$EnemyDeathAnimation.hide()
	$Body.play(color + "idle")

func enemy_movement(delta) -> void:
	get_parent().progress += speed * delta

# Manage animation based on x velocity
# x == 0 = reverse from L/R animation then idle
func play_animation() -> void:
	if get_parent().global_position.x == previous_frame_x_position:
		if $Body.animation == color + "start_move" and $Body.frame == 0:
			$Body.animation = color + "idle"
		elif $Body.animation == color + "start_move":
			$Body.play_backwards(color + "start_move")
		elif $Body.animation == color + "move" and $Body.frame == 0:
			$Body.play_backwards(color + "start_move")
		elif $Body.animation == color + "move":
			$Body.play_backwards(color + "move")
	else:
		if $Body.animation == color + "idle":
			$Body.play(color + "start_move")
		elif $Body.animation == color + "start_move" and $Body.frame == 3:
			$Body.play(color + "move")
	if $Body.animation == color + "idle" or get_parent().global_position.x > previous_frame_x_position:
		$Body.set_flip_h(false)
	elif get_parent().global_position.x < previous_frame_x_position:
		var test = [get_parent().global_position.x, previous_frame_x_position]
		$Body.set_flip_h(true)
	previous_frame_x_position = get_parent().global_position.x

func play_death_animation() -> void:
	$EnemyDeathAnimation.show()
	$EnemyDeathAnimation.self_modulate = $EnemyDeathAnimation.self_modulate.lerp(Color(1,1,1,0), .2)
	$EnemyDeathAnimation.scale += $EnemyDeathAnimation.scale * .05
	if particles in get_children():
		particles.modulate.a = $EnemyDeathTimer.time_left * 1 / $EnemyDeathTimer.wait_time

func load_enemy():
	set_color(GameState.data["enemy"][enemy_name]["color"])
	set_speed(GameState.data["enemy"][enemy_name]["speed"])
	set_health(GameState.data["enemy"][enemy_name]["health"])
	set_pattern(GameState.data["enemy"][enemy_name]["pattern"])
	set_death_pattern(GameState.data["enemy"][enemy_name]["death_pattern"])

# Instantiate a new bullethandler, set its is_boss to false, set its parent to this.name and this.index
# then delete the pattern from the pattern_list after it finishes its loop timer
func play_pattern(pattern : String) -> void:
	var new_bullet_handler = bullet_handler.instantiate()
	new_bullet_handler.set_parent(false, enemy_name, enemy_index, pattern)
	add_child(new_bullet_handler)
	new_bullet_handler.add_to_group("patterns" + str(enemy_index))

func play_death_patterns() -> void:
	for death_pattern in death_pattern_list:
		play_pattern(death_pattern)

func set_enemy_name(name : String) -> void:
	enemy_name = name

func set_color(clr : String) -> void:
	color = clr

func set_speed(value : int) -> void:
	speed = value

func set_health(value : int) -> void:
	health = value

func set_pattern(pattern_names : Array) -> void:
	pattern_list = pattern_names.duplicate(true)

func set_death_pattern(death_pattern_names : Array) -> void:
	death_pattern_list = death_pattern_names.duplicate(true)

func set_drop_item(item_name : String) -> void:
	drop_item = item_name

func UpdateEnemyGameState() -> void:
	if not enemy_gamestate_appended:
		enemy_index = GameState.enemy_gamestate.size()
		GameState.enemy_gamestate.append([global_position.x, global_position.y, pattern_list])
		enemy_gamestate_appended = true
	elif enemy_gamestate_appended:
		GameState.enemy_gamestate[enemy_index] = [global_position.x, global_position.y, pattern_list]

func get_hit() -> void:
	if not flashing:
		flashing = true
		await get_tree().create_timer(0.15).timeout
		flashing = false
	health -= 5

func flash() -> void:
	$Body.material.set_shader_parameter("solid_color", Color.WHITE)

func perish() -> void:
	dead = true
	pattern_list.clear()
	get_tree().call_group("patterns" + str(enemy_index), "set_stop_firing", true) # TODO may be redundant
	get_tree().call_group("runes" + str(enemy_index), "perish")
	$EnemyHitBox.queue_free()
	$EnemyDeathTimer.start()
	$Body.hide()
	play_death_patterns()
	spawn_item()
	generate_particles("death")

func spawn_item() -> void:
	var new_item = item.instantiate()
	new_item.set_type(drop_item)
	new_item.position = position
	new_item.linear_velocity = Vector2(randf_range(-23.0, 23.0), randf_range(-29.0, -23.0))
	get_parent().add_child(new_item)

func generate_particles(type : String) -> void:
	if type == "death":
		particles = particles_scene.instantiate()
		add_child(particles)
		particles.emitting = true
		particles.process_material.scale_max = .5
		particles.set_modulate(Color.ORANGE_RED)
		particles.add_to_group("enemy_particles")

func set_distance_to_stop_point(progress : float) -> void:
	distance_to_stop_point = progress

func set_fire_while_moving(argument : bool) -> void:
	fire_while_moving = argument

func _on_visible_on_screen_notifier_2d_screen_exited():
	if on_screen:
		on_screen = false
		get_tree().call_group("runes" + str(enemy_index), "perish")
		queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered():
	on_screen = true
