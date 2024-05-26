extends Sprite2D
@onready var ripple = $Ripple
var pulse_starting_rotation : float = 0.0
var pulse_progress : float = 1.0
var shield_energy : int = 255
var shield_stagger : int = 0
var shield_regeneration_timer : float = 0.1
var shield_active_last_frame : bool = false
var load_progress : float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	start_new_pulse()
	if load_progress >= 1.0:
		ripple.show()
		rotate(deg_to_rad(1))
		ripple.rotation = -rotation + pulse_starting_rotation
	elif load_progress <= 0.0:
		rotation = 0.0
	pulse_progress += delta
	pulse_progress = clamp(pulse_progress, 0.0, 1.0)
	shape_shield()
	if load_progress > 0.5:
		pass
	ripple.offset.x = -32.0 + (64.0 * pulse_progress)
	ripple.region_rect = Rect2(0.0, 200.0 * pulse_progress * randf(), 12, 64 * sqrt(1 - 4 * pow(pulse_progress - 0.5, 2)))
	flip()
	# Handle shield regeneration
	regenerate_shield()
	# Handle shield damage
	if shield_stagger > 0:
		damage_shield()
	# Handle shield bar update
	update_shield_bar()

func shape_shield() -> void:
	var xy = 32.0 - 32.0 * load_progress
	var wh = load_progress * 64.0
	set_region_rect(Rect2(0.0, xy, 64.0, wh))
	self_modulate.a = load_progress

func start_new_pulse() -> void:
	if pulse_progress == 1.0:
		pulse_progress = 0.0
		pulse_starting_rotation = randf_range(0.0, PI)
		ripple.rotation = pulse_starting_rotation

func flip() -> void:
	if Engine.get_frames_drawn() % 3 == 0:
		ripple.flip_h = !ripple.flip_h
	if Engine.get_frames_drawn() % 5 == 0:
		ripple.flip_v = !ripple.flip_v

func shield(delta : float, is_shielded : bool) -> void:
	if is_shielded:
		show()
		load_progress = min(load_progress + delta, 1.0)
	else:
		hide()
		load_progress = max(load_progress - delta, 0.0)
	shield_active_last_frame = is_shielded

# Reduces shield durability
func damage_shield() -> void:
	shield_energy -= min(10, shield_stagger)
	shield_regeneration_timer = min(1.0, shield_regeneration_timer + .05)
	$ShieldRegenerationTimer.start(shield_regeneration_timer)
	shield_energy = clamp(shield_energy, -50, 255)
	shield_stagger -= max(10, shield_stagger * .05)
	shield_stagger = clamp(shield_stagger, 0, 255)

func regenerate_shield() -> void:
	if $ShieldRegenerationTimer.is_stopped():
		shield_energy += 1
		shield_regeneration_timer = 0.1

func update_shield_bar() -> void:
	$ShieldLifeBar.set_value_no_signal(shield_energy)
	$ShieldLifeDebtBar.set_value_no_signal(max(0.0, -shield_energy))
	$ShieldStaggerBar.set_value_no_signal(shield_stagger)
