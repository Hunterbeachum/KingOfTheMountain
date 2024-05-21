extends RigidBody2D
var item_type : String
var magnetized : bool = false
var collision_name : String = "item"
var distance_from_player_on_magnetization : float = 0.0


func _ready():
	item_start()

func _process(delta):
	if magnetized:
		gravity_scale = 0.0
		$AttractBox.set_deferred("disabled", true)
		global_position += Vector2(GameState.player_position - global_position).normalized() * 300.0 * delta
	else:
		$AttractBox.set_deferred("disabled", false)

func item_start():
	$Icon.play(item_type)

func set_magnetize(value):
	magnetized = value
	if magnetized and distance_from_player_on_magnetization == 0.0:
		distance_from_player_on_magnetization = global_position.distance_to(GameState.player_position)

func set_type(type_name : String) -> void:
	item_type = type_name

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()
