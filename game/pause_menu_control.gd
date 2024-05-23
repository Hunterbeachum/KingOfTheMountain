extends Control
@onready var pointer = $Pointer
var t : float = 0.0

func _ready():
	pass # Replace with function body.


func _process(delta):
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = false
		queue_free()
	t += delta
	pointer.color.a = (sin(2*t) + 2.0) / 3.0
