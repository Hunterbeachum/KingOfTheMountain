extends RigidBody2D
var homing = true
var collision_name = "bullet"
var initial_speed : float
var current_speed: float
var updates_queue : Array
var active_updates : Array
var time_passed : float
var stored_linear_velocity : Vector2
var disappearing : bool = false
var pausing : bool = false
var hitbox_active : bool = true
@onready var bullet_lifespan = $BulletLifespan
@onready var bullet_hitbox = $BulletHitBox
@export var particles_scene : PackedScene
var particles : GPUParticles2D


# Called when the node enters the scene tree for the first time.
func _ready():
	name = "BULLET"
	add_to_group("active_bullets")
	$BulletLifespan.start()
	show()
	stored_linear_velocity = linear_velocity
	initial_speed = abs(linear_velocity.x) + abs(linear_velocity.y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	update_time_passed()
	update_current_speed()
	if disappearing:
		destroy_hitbox()
		linear_velocity = Vector2.ZERO
		$Body.self_modulate = $Body.self_modulate.lerp(Color(1,1,1,0), .2)
		$Body.scale += $Body.scale * .1
		if $Body.get_self_modulate().a < .1:
			queue_free()
	if pausing:
		linear_velocity = linear_velocity.lerp(Vector2.ZERO, .05)
	elif not pausing:
		linear_velocity = linear_velocity.lerp(stored_linear_velocity, .05)
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

func destroy_hitbox() -> void:
	if hitbox_active:
		bullet_hitbox.queue_free()
		hitbox_active = false

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
			resume()
		elif update_name == "change_direction":
			change_direction(active_update[3])
		if active_update[2] == -1:
			active_updates.erase(active_update)
		elif time_passed > active_update[2] * .001:
			active_updates.erase(active_update)

func accelerate(magnitude : float) -> void:
	if (0.50 * initial_speed) < current_speed:
		linear_velocity = linear_velocity.lerp(linear_velocity * magnitude, .001)

func home(magnitude : float) -> void:
	var direction = linear_velocity.angle()
	var target_direction = global_position.angle_to_point(GameState.player_position)
	var diff = target_direction - direction
	linear_velocity = Vector2(initial_speed, 0.0).rotated(direction + diff * (magnitude * .001))

func pause() -> void:
	pausing = true
	stored_linear_velocity = linear_velocity

func resume() -> void:
	pausing = false

func change_direction(magnitude : float) -> void:
	linear_velocity = linear_velocity.rotated(PI / magnitude)
	stored_linear_velocity = stored_linear_velocity.rotated(PI / magnitude)

func update_time_passed() -> void:
	time_passed = 60.0 - bullet_lifespan.time_left

func set_updates(updates : Array) -> void:
	updates_queue = updates.duplicate(true)

func update_current_speed() -> void:
	current_speed = abs(linear_velocity.x) + abs(linear_velocity.y)

func disappear() -> void:
	disappearing = true
# TODO delete the bullet if it collides w/ the player
# TODO animate bullets being deleted from collision/bombs

func generate_particles() -> void:
	particles = particles_scene.instantiate()
	add_child(particles)
	particles.emitting = true
	particles.process_material.scale_max = .5
	particles.set_modulate(Color.ORANGE_RED)
	particles.add_to_group("bullet_particles")
