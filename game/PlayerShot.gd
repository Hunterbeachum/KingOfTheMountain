extends RigidBody2D


# Called when the node enters the scene tree for the first time.
func _ready():
	$Body.play("marisa")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass


func _on_body_entered(body):
	linear_velocity = Vector2.ZERO
	body.get_hit()
	$Body.play("marisa_hit")
