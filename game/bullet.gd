extends RigidBody2D
var homing = true
var collision_name = "bullet"
var speed : float
@onready var bullet_lifespan = $BulletLifespan

# Called when the node enters the scene tree for the first time.
func _ready():
	$BulletLifespan.start()
	show()
	speed = abs(linear_velocity.x) + abs(linear_velocity.y)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	# get_tree().call_group("bullets", "_update_linear_velocity", $Player.position)
	pass


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func _update_linear_velocity(pos):
	if position.distance_to(pos) < 50:
		homing = false
	# TODO logic is all wrong
	if $BulletLifespan.time_left < 6:
		var direction = position.angle_to_point(pos)
		var old_linear_velocity = linear_velocity
		var new_linear_velocity = Vector2(100.0, 0.0).rotated(direction)
		var comparison = (new_linear_velocity - old_linear_velocity)
		linear_velocity = old_linear_velocity + .5 * comparison

func _zero_velocity():
	linear_velocity = linear_velocity * .04
	set_linear_damp(0.0)

func accelerate(age : float, magnitude : float) -> void:
	if 60.0 - bullet_lifespan.time_left > age:
		linear_velocity = linear_velocity.lerp(linear_velocity * magnitude, .001)

func home(age : float, magnitude : float) -> void:
	if 60.0 - bullet_lifespan.time_left > age:
		var direction = linear_velocity.angle()
		var target_direction = position.angle_to_point(GameState.player_position)
		var diff = target_direction - direction
		linear_velocity = Vector2(speed, 0.0).rotated(target_direction + diff * .99)

# TODO delete the bullet if it collides w/ the player
# TODO animate bullets being deleted from collision/bombs
