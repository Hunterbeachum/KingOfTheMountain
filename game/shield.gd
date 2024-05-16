extends Sprite2D
@onready var ripple = $Ripple
var starting_rotation : float = 0.0
var progress : float = 1.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	start_new_pulse()
	rotate(deg_to_rad(1))
	progress += delta
	progress = clamp(progress, 0.0, 1.0)
	ripple.offset.x = -32.0 + (64.0 * progress)
	ripple.region_rect = Rect2(0.0, 200.0 * progress * randf(), 12, 64 * sqrt(1 - 4 * pow(progress - 0.5, 2)))
	flip()
	pass

func start_new_pulse() -> void:
	if progress == 1.0:
		progress = 0.0
		starting_rotation = randf_range(0.0, PI)
		ripple.rotation = starting_rotation

func flip() -> void:
	if Engine.get_frames_drawn() % 3 == 0:
		ripple.flip_h = !ripple.flip_h
	if Engine.get_frames_drawn() % 5 == 0:
		ripple.flip_v = !ripple.flip_v
