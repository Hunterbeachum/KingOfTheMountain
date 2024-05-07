extends Sprite2D
var destination : Vector2 = Vector2.ZERO
@onready var aura = $Aura
var rune_alpha : float = 1.0
var disappearing : bool = false
var circling : bool = false
var fired_at_player : bool = false
var speed : int
var degrees : float = 0.0
var parent_index : int
var pattern_name : String

func _ready():
	pass # Replace with function body.

func _process(delta):
	if circling:
		degrees += 1
		destination = Vector2(GameState.enemy_gamestate[parent_index][0], GameState.enemy_gamestate[parent_index][1]) + Vector2(80.0, 0.0).rotated(deg_to_rad(degrees))
		position = position.lerp(destination, 0.1)
	elif fired_at_player:
		position = position + Vector2(speed * delta, 0.0).rotated(position.angle_to_point(destination))
	else:
		position = position.lerp(destination, 0.02)
	if disappearing and modulate.a < .1:
		queue_free()
	fade()
	rotation += PI/180
	aura.set_rotation(-2 * rotation)

func fade() -> void:
	set_modulate(modulate.lerp(Color(1,1,1,rune_alpha), .05))

func perish() -> void:
	rune_alpha = 0.0
	disappearing = true

func _on_visible_on_screen_notifier_2d_screen_exited():
	get_tree().call_group("patterns" + str(parent_index), "stop_fire")
	queue_free()
