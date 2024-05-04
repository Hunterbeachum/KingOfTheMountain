extends RigidBody2D
var homing = true
var collision_name = "bullet"
var initial_speed : float
var current_speed: float
var updates_queue : Array
var active_updates : Array
var time_passed : float
var stored_linear_velocity : Vector2
@onready var bullet_lifespan = $BulletLifespan

# Called when the node enters the scene tree for the first time.
func _ready():
	$BulletLifespan.start()
	show()
	initial_speed = abs(linear_velocity.x) + abs(linear_velocity.y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_time_passed()
	update_current_speed()
	if not updates_queue.is_empty():
		if 60.0 - bullet_lifespan.time_left > updates_queue[0][1] * .001:
			active_updates.append(updates_queue.pop_front())
	if not active_updates.is_empty():
		run_update(active_updates)
	pass


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _zero_velocity():
	linear_velocity = linear_velocity * .04
	set_linear_damp(0.0)

func run_update(active_update_list : Array):
	for active_update in active_update_list:
		var update_name = active_update[0]
		if update_name == "accelerate":
			accelerate(active_update[3])
		elif update_name == "homing":
			home(active_update[3])
		elif update_name == "pause":
			pause()
		elif update_name == "resume":
			resume(active_update[3])
		if active_update[2] == -1:
			active_updates.erase(active_update)
		elif time_passed > active_update[2] * .001:
			active_updates.erase(active_update)

func accelerate(magnitude : float) -> void:
	if (0.50 * initial_speed) < current_speed:
		linear_velocity = linear_velocity.lerp(linear_velocity * magnitude, .001)

func home(magnitude : float) -> void:
	var direction = linear_velocity.angle()
	var target_direction = position.angle_to_point(GameState.player_position)
	var diff = target_direction - direction
	linear_velocity = Vector2(initial_speed, 0.0).rotated(direction + diff * (magnitude * .001))

func pause() -> void:
	stored_linear_velocity = linear_velocity
	linear_velocity = Vector2.ZERO

func resume(magnitude : float) -> void:
	linear_velocity = stored_linear_velocity * max(magnitude, 1) * .001

func update_time_passed() -> void:
	time_passed = 60.0 - bullet_lifespan.time_left

func set_updates(updates : Array) -> void:
	updates_queue = updates.duplicate(true)

func update_current_speed() -> void:
	current_speed = abs(linear_velocity.x) + abs(linear_velocity.y)

# TODO delete the bullet if it collides w/ the player
# TODO animate bullets being deleted from collision/bombs
