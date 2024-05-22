extends Menu

func _ready():
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	configure_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
