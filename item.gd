extends RigidBody2D
var item_type : String
var magnetized : bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	item_start()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if magnetized:
		$AttractBox.set_deferred("disabled", true)
		position = position.lerp(GameState.player_position, .1)
	else:
		$AttractBox.set_deferred("disabled", false)

func item_start():
	$Icon.play(item_type)

func set_magnetize(value):
	magnetized = value
