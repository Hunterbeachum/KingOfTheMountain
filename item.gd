extends RigidBody2D
var item_type : String
var magnetized : bool = false
var collision_name : String = "item"


func _ready():
	item_start()

func _process(delta):
	if magnetized:
		$AttractBox.set_deferred("disabled", true)
		global_position = global_position.lerp(GameState.player_position, .2)
	else:
		$AttractBox.set_deferred("disabled", false)

func item_start():
	$Icon.play(item_type)

func set_magnetize(value):
	magnetized = value

func set_type(type_name : String) -> void:
	item_type = type_name

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
