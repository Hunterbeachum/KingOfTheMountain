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
var placed : bool = false
signal start_pattern
var t : float = 0.0
var path_points : Array = []


func _ready():
	if not circling and not fired_at_player:
		create_path()

func _process(delta):
	t = min(t + delta, 1.0)
	signal_start()
	if circling:
		degrees += 1
		destination = Vector2(GameState.enemy_gamestate[parent_index][0], GameState.enemy_gamestate[parent_index][1]) + Vector2(80.0, 0.0).rotated(deg_to_rad(degrees))
		position = position.lerp(destination, 0.1)
	elif fired_at_player:
		position = position + Vector2(speed * delta, 0.0).rotated(position.angle_to_point(destination))
	else:
		$Aura.global_position = destination
		$Aura.self_modulate.a = t
		$Aura.set_scale(Vector2(2.0 - t, 2.0 - t))
		if t < 1.0:
			position = _cubic_bezier(path_points[0], path_points[1], path_points[2], path_points[3])
	if disappearing and modulate.a < .1:
		queue_free()
	fade()
	rotation += PI/180
	aura.set_rotation(-2 * rotation)

func create_path() -> void:
	const Y_DIP = 40.0
	var start_x = GameState.enemy_gamestate[parent_index][0]
	var start_y = GameState.enemy_gamestate[parent_index][1]
	var x_diff = destination.x - start_x
	var point1 = Vector2(start_x - (0.0 * x_diff), start_y + Y_DIP)
	var point2 = Vector2(start_x + (1.5 * x_diff), start_y + Y_DIP)
	path_points += [Vector2(start_x, start_y), point1, point2, destination]

func _cubic_bezier(p0 : Vector2, p1 : Vector2, p2 : Vector2, p3 : Vector2) -> Vector2:
	var q0 = p0.lerp(p1, t)
	var q1 = p1.lerp(p2, t)
	var q2 = p2.lerp(p3, t)
	
	var r0 = q0.lerp(q1, t)
	var r1 = q1.lerp(q2, t)
	
	var s = r0.lerp(r1, t)
	return s

func fade() -> void:
	set_modulate(modulate.lerp(Color(1,1,1,rune_alpha), .05))

func perish() -> void:
	rune_alpha = 0.0
	disappearing = true

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()

func signal_start() -> void:
	if (t == 1.0 and not placed) or (fired_at_player and not placed):
		emit_signal("start_pattern")
		placed = true
