extends Sprite2D
@onready var ripple = $Ripple
var pulse_starting_rotation : float = 0.0
var pulse_progress : float = 1.0
var shield_ready : bool = false
var active_shield : bool = true
var shield_energy : int = 255
var shield_stagger : int = 0
var shield_regeneration_timer : float = 0.1
var shield_active_last_frame : bool = false
var load_progress : float = 0.0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	start_new_pulse()
	ripple.visible = true if load_progress >= 1.0 else false
	if load_progress >= 1.0:
		rotate(deg_to_rad(1))
		ripple.rotation = -rotation + pulse_starting_rotation
	elif load_progress <= 0.0:
		rotation = 0.0
	for bar in [$ShieldStaggerBar, $ShieldLifeBar, $CastProgressBar]:
		bar.rotation = -rotation
	pulse_progress += delta
	pulse_progress = clamp(pulse_progress, 0.0, 1.0)
	shape_shield()
	ripple.offset.x = -32.0 + (64.0 * pulse_progress)
	ripple.region_rect = Rect2(0.0, 200.0 * pulse_progress * randf(), 12, 64 * sqrt(1 - 4 * pow(pulse_progress - 0.5, 2)))
	flip()
	# Handle shield damage
	if shield_stagger > 0:
		damage_shield()
	# Handle shield bar update
	update_shield_bar()

func cast_shield(delta : float, is_casting : bool) -> void:
	if is_casting:
		load_progress = min(load_progress + 0.2 * delta, 1.0)
	else:
		load_progress = max(load_progress - 0.05 * delta, 0.0)
	if load_progress >= 1.0:
		ready_shield()

func ready_shield() -> void:
	shield_ready = true
	$ShieldReadyTimer.start()

func shape_shield() -> void:
	if shield_ready:
		if $ShieldReadyTimer.time_left > 0.0:
			$ShieldCastBar.scale = Vector2(1.0 + $ShieldReadyTimer.time_left, 1.0 + $ShieldReadyTimer.time_left)
	var xy = 32.0 - 32.0 * load_progress
	var wh = load_progress * 64.0
	#set_region_rect(Rect2(0.0, xy, 64.0, wh))
	if load_progress > 0.0:
		$CastProgressBar.set_value_no_signal(load_progress * 5000)
	$ShieldCastBar.set_value_no_signal(1000 * load_progress)
	if load_progress < 1.0:
		$ShieldCastBar.modulate.a = 0.1
	else:
		$ShieldCastBar.modulate.a = 1.0

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

func shield() -> void:
	show()
	$ShieldLifeBar.set_value_no_signal(255)
	$ShieldLifeBar.show()
	active_shield = true

# Reduces shield durability
func damage_shield() -> void:
	shield_energy -= min(10, shield_stagger)
	shield_regeneration_timer = min(1.0, shield_regeneration_timer + .05)
	$ShieldRegenerationTimer.start(shield_regeneration_timer)
	shield_energy = clamp(shield_energy, -50, 255)
	shield_stagger -= max(10, shield_stagger * .05)
	shield_stagger = clamp(shield_stagger, 0, 255)

func update_shield_bar() -> void:
	$ShieldLifeBar.set_value_no_signal(shield_energy)
	$ShieldStaggerBar.set_value_no_signal(shield_stagger)
