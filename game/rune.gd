extends Sprite2D
var destination : Vector2 = Vector2.ZERO
@onready var aura = $Aura
var rune_alpha : float = 1.0


func _ready():
	pass # Replace with function body.

func _process(delta):
	fade()
	rotation += PI/180
	aura.set_rotation(-2 * rotation)
	position = position.lerp(destination, 0.01)

func fade() -> void:
	set_modulate(modulate.lerp(Color(1,1,1,rune_alpha), .05))
