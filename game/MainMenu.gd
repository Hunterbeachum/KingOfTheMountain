extends Menu
var fade = false

func _ready():
	set_modulate(Color(0,0,0,0))
	await get_tree().create_timer(2).timeout
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	configure_focus()
	fade = true

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if fade:
		set_modulate(lerp(get_modulate(), Color(1,1,1,1), 0.04))
	pass

