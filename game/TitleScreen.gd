extends Control

var t : float = 0.0
var fading_in = true
@onready var pointer = $Pointer

# Sets children modulate to black (includes Background, creating a fully black screen)
# Hides the menu pointer for 3 seconds.
func _ready():
	set_modulate(Color(0,0,0,1))
	$Pointer.hide()
	await get_tree().create_timer(3).timeout
	$Pointer.show()

func _process(delta):
	t += delta
	pointer.color.a = (sin(2*t) + 3.0) / 4.0
	fade(delta)

# Fades the entire scene from black to white
func fade(delta):
	modulate += Color(delta, delta, delta, 0) if fading_in else Color(-delta, -delta, -delta, 0)
	modulate.r = clamp(modulate.r, 0.0, 1.0)
	modulate.g = clamp(modulate.g, 0.0, 1.0)
	modulate.b = clamp(modulate.b, 0.0, 1.0)

# Fades for 3s before starting a new game.  Happens when a new game is selected from the title screen.
func close() -> void:
	fading_in = false
	await get_tree().create_timer(3).timeout
	SignalBus.menu_command.emit("NewGame")
