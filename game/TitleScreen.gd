extends Control

var t : float = 0.0
var fading_in = true

# Sets children modulate to black (includes Background, creating a fully black screen)
# Hides the menu pointer for 3 seconds.
func _ready():
	set_modulate(Color(0,0,0,1))
	$Pointer.hide()
	await get_tree().create_timer(3).timeout
	$Pointer.show()

func _process(delta):
	fade(delta)

# Fades the entire scene from black to white
func fade(delta : float):
	t = min(t + delta, 1.0) if fading_in else max(t - delta, 0.0)
	set_modulate(lerp(Color(0,0,0,1), Color(1,1,1,1), t))

# Fades for 3s and then.  Happens when a new game is selected from the title screen.
func close() -> void:
	fading_in = false
	await get_tree().create_timer(3).timeout
	SignalBus.menu_command.emit("NewGame")
