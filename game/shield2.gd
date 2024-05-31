extends Sprite2D
@onready var ripple = $Ripple
@onready var shield_charge_bar = $CastProgressBar
var pulse_starting_rotation : float = 0.0
var pulse_progress : float = 1.0
var shield_ready : bool = false
var shield_active : bool = false
var shield_stagger : int = 0
var shield_active_last_frame : bool = false
var test = 0

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	animate_shield(delta)
	# Handle shield damage
	if shield_stagger > 0:
		damage_shield()

func cast_shield(delta : float, is_casting : bool) -> void:
	if shield_ready:
		if Engine.get_frames_drawn() % 10 == 0:
			shield_charge_bar.self_modulate = Color(randf_range(0.7, 1.0), randf_range(0.7, 1.0), randf_range(0.7, 1.0))
	if not shield_active and not shield_ready:
		if is_casting:
			shield_charge_bar.self_modulate.a = lerp(shield_charge_bar.self_modulate.a, 1.0, 0.07)
			$ShieldCastBar.self_modulate.a = lerp($ShieldCastBar.self_modulate.a, 0.2, 0.1)
			shield_charge_bar.set_value_no_signal(shield_charge_bar.value + delta * 200)
		else:
			shield_charge_bar.self_modulate.a = lerp(shield_charge_bar.self_modulate.a, 0.3, 0.07)
			$ShieldCastBar.self_modulate.a = lerp($ShieldCastBar.self_modulate.a, 0.0, 0.1)
			shield_charge_bar.set_value_no_signal(shield_charge_bar.value - delta * 500)
		if shield_charge_bar.value >= 5000:
			ready_shield()
		$ShieldCastBar.set_value_no_signal(shield_charge_bar.value)

func ready_shield() -> void:
	shield_ready = true
	$ShieldReadyTimer.start()

func animate_shield(delta) -> void:
	start_new_pulse(delta)
	if not $ShieldReadyTimer.is_stopped():
		alert_ready()
		self_modulate.a = 0.5 * (2 * $ShieldReadyTimer.time_left)
		scale = Vector2(4.0 - (6 * $ShieldReadyTimer.time_left), 4.0 - (6 * $ShieldReadyTimer.time_left))
	elif not shield_active:
		$ShieldReadyText.hide()
		self_modulate.a = lerp(self_modulate.a, 0.0, 0.05)
	if shield_ready:
		$ShieldCastBar.hide()
	elif shield_active:
		self.modulate.a = float(shield_charge_bar.value) / 5000.0
		rotate(deg_to_rad(1))
		ripple.rotation = -rotation + pulse_starting_rotation
	else:
		$ShieldCastBar.show()
		rotation = 0.0
	# Method to shape the shield if I wanted the shield to spawn in differently
	#var xy = 32.0 - 32.0 * load_progress
	#var wh = load_progress * 64.0
	#set_region_rect(Rect2(0.0, xy, 64.0, wh))
	shield_charge_bar.rotation = -rotation
	shield_charge_bar.scale = Vector2.ONE / scale

func start_new_pulse(delta) -> void:
	ripple.visible = true if shield_active else false
	pulse_progress += delta
	pulse_progress = clamp(pulse_progress, 0.0, 1.0)
	if pulse_progress == 1.0:
		pulse_progress = 0.0
		pulse_starting_rotation = randf_range(0.0, PI)
		ripple.rotation = pulse_starting_rotation
	ripple.offset.x = -32.0 + (64.0 * pulse_progress)
	ripple.region_rect = Rect2(0.0, 200.0 * pulse_progress * randf(), 12, 64 * sqrt(1 - 4 * pow(pulse_progress - 0.5, 2)))
	animate_electricity()

func alert_ready() -> void:
	$ShieldReadyText.show()
	$ShieldReadyText.self_modulate.a = ($ShieldReadyTimer.time_left * 2.0)
	$ShieldReadyText.scale = Vector2.ONE / scale

func animate_electricity() -> void:
	if Engine.get_frames_drawn() % 3 == 0:
		ripple.flip_h = !ripple.flip_h
	if Engine.get_frames_drawn() % 5 == 0:
		ripple.flip_v = !ripple.flip_v

func deploy_shield() -> void:
	if shield_ready:
		SignalBus.shield_burst.emit()
		shield_charge_bar.self_modulate = Color("WHITE")
		shield_ready = false
		shield_active = true
		self_modulate.a = 1.0
		scale = Vector2.ONE

# Reduces shield durability
func damage_shield() -> void:
	shield_charge_bar.set_value_no_signal(shield_charge_bar.value - min(100, shield_stagger))
	shield_stagger -= max(100, shield_stagger * .05)
	shield_stagger = clamp(shield_stagger, 0, 255)
	if shield_charge_bar.value == 0:
		break_shield()

func break_shield() -> void:
	shield_active = false
	$ShieldReadyTimer.start()
	SignalBus.shield_burst.emit()
	shield_charge_bar.set_value_no_signal(0.0)
	$ShieldCastBar.set_value_no_signal(0.0)
	shield_stagger = 0
