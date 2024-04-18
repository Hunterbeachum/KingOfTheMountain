extends RigidBody2D
var homing = true

# Called when the node enters the scene tree for the first time.
func _ready():
	$BulletLifespan.start()
	show()


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

