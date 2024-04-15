extends RigidBody2D
var bullet_lifespan = 0
var homing = true

# Called when the node enters the scene tree for the first time.
func _ready():
	show()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _update_bullet_lifespan():
	bullet_lifespan += 1

func _update_linear_velocity(pos):
	if position.distance_to(pos) < 50:
		homing = false
	if bullet_lifespan < 6 and bullet_lifespan >= 1 and homing == true:
		var direction = position.angle_to_point(pos)
		var old_linear_velocity = linear_velocity
		var new_linear_velocity = Vector2(100.0, 0.0).rotated(direction)
		var comparison = (new_linear_velocity - old_linear_velocity)
		linear_velocity = old_linear_velocity + .5 * comparison


func _zero_velocity():
	linear_velocity = linear_velocity * .04
	set_linear_damp(0.0)

