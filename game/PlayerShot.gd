extends Area2D

var speed : int = 1000
var velocity : Vector2 = Vector2.ZERO

func _ready():
	$Body.play("marisa")

func _process(delta):
	velocity.y = -speed * delta
	translate(velocity)
	if $Body.animation == "marisa_hit" and $Body.frame == 2:
		queue_free()

func _on_body_entered(body):
	$ShotHitBox.set_deferred("disabled", true)
	speed = 0
	body.get_hit()
	$Body.play("marisa_hit")
	pass
