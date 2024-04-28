extends RigidBody2D
var color : String = ""
var stop_position : Vector2
var leave_position : Vector2
var current_destination : Vector2
var enemy_name : String = ""
var speed : int = 0
var health : int = 100
var pattern_list : Array = []
var death_pattern : Array = []
var enemy_gamestate_appended : bool = false
var enemy_index : int
var flashing : bool = false
@export var bullet_handler: PackedScene


func _ready():
	load_enemy(enemy_name)
	start()
	enemy_movement(stop_position)
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	UpdateEnemyGameState()
	if $EnemyDeathTimer.time_left > 0:
		$EnemyDeathAnimation.show()
		$EnemyDeathAnimation.self_modulate = $EnemyDeathAnimation.self_modulate.lerp(Color(1,1,1,0), .2)
		$EnemyDeathAnimation.scale += $EnemyDeathAnimation.scale * .1
	if health <= 0 and $Body.visible:
		perish()
	if not $Body.visible:
		if len(get_tree().get_nodes_in_group("bullets" + str(enemy_index))) <= 0:
			queue_free()
	if flashing and Engine.get_frames_drawn() % 3 == 0:
		flash()
		var test = get_parent().get_children()
		pass
	else:
		$Body.material.set_shader_parameter("solid_color", Color(1, 1, 1, 0))
	if current_destination != null:
		if position.distance_to(current_destination) < 5:
			linear_velocity = Vector2.ZERO
			if current_destination == stop_position:
				for pattern in pattern_list:
					if not pattern[1]:
						# TODO is this changing the pattern_list or just the iterator?
						pattern[1] = not pattern[1]
						play_pattern(pattern[0])
	# Manage animation based on x velocity
	# x == 0 = reverse from L/R animation then idle
	if linear_velocity.x == 0:
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
	if linear_velocity.x > 0 or $Body.animation == color + "idle":
		$Body.set_flip_h(false)
	elif linear_velocity.x < 0:
		$Body.set_flip_h(true)

func start() -> void:
	show()
	$EnemyDeathAnimation.hide()
	$Body.play(color + "idle")

func enemy_movement(destination) -> void:
	current_destination = destination
	var direction = position.angle_to_point(current_destination)
	linear_velocity = Vector2(speed, 0.0).rotated(direction)

func load_enemy(name : String):
	enemy_name = name
	set_color(GameState.data["enemy"][enemy_name]["color"])
	set_speed(GameState.data["enemy"][enemy_name]["speed"])
	set_health(GameState.data["enemy"][enemy_name]["health"])
	set_pattern(GameState.data["enemy"][enemy_name]["pattern"])

# Instantiate a new bullethandler, set its is_boss to false, set its parent to this.name and this.index
# then delete the pattern from the pattern_list after it finishes its loop timer
func play_pattern(pattern : String) -> void:
	var new_bullet_handler = bullet_handler.instantiate()
	new_bullet_handler.set_parent(false, enemy_name, enemy_index, pattern)
	add_child(new_bullet_handler)
	new_bullet_handler.add_to_group("patterns" + str(enemy_index))
	await get_tree().create_timer(GameState.data["pattern"][pattern]["loop_time"]).timeout
	pattern_list.erase([pattern, true])

func set_enemy_name(name : String) -> void:
	enemy_name = name

func set_color(clr : String) -> void:
	color = clr

func set_stop_position(pos : Vector2) -> void:
	stop_position = pos

func set_leave_position(pos : Vector2) -> void:
	leave_position = pos

func set_speed(value : int) -> void:
	speed = value

func set_health(value : int) -> void:
	health = value

func set_pattern(pattern_names : Array) -> void:
	for pattern in pattern_names:
		pattern_list.append([pattern, false])

func set_death_pattern(pattern_name : Array) -> void:
	death_pattern = pattern_name

func UpdateEnemyGameState() -> void:
	if not enemy_gamestate_appended:
		enemy_index = GameState.enemy_gamestate.size()
		GameState.enemy_gamestate.append([position.x, position.y, pattern_list])
		enemy_gamestate_appended = true
	elif enemy_gamestate_appended:
		GameState.enemy_gamestate[enemy_index] = [position.x, position.y, pattern_list]


func get_hit() -> void:
	if not flashing:
		flashing = true
		await get_tree().create_timer(0.25).timeout
		flashing = false
	health -= 5

func flash() -> void:
	#TODO this is affecting all of the enemies referencing the AnimatedSprite2D bodies.
	$Body.material.set_shader_parameter("solid_color", Color.WHITE)

func perish() -> void:
	get_tree().call_group("patterns" + str(enemy_index), "stop_fire")
	$EnemyHitBox.set_deferred("disabled", false)
	$EnemyDeathTimer.start()
	$Body.hide()
