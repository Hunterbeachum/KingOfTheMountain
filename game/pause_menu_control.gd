extends Control
@onready var pointer = $Pointer
var game_over : bool = false
var t : float = 0.0

func _ready():
	if game_over:
		$MarginContainer/CenterContainer/Pause.queue_free()
		$MarginContainer/PauseMenu/Resume.set_modulate(Color(0.5,0.5,0.5,0.5))
	else:
		$MarginContainer/CenterContainer/GameOver.queue_free()

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		get_tree().paused = false
		queue_free()
	t += delta
	pointer.color.a = (sin(2*t) + 2.0) / 3.0
