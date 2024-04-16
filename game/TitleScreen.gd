extends Control
signal newgame
signal options
signal quit
var fade = false

# Called when the node enters the scene tree for the first time.
func _ready():
	set_modulate(Color(0,0,0,1))
	$Pointer.hide()
	await get_tree().create_timer(3).timeout
	$Pointer.show()
	pass # Replace with function body.

func fade_in():
	set_modulate(lerp(get_modulate(), Color(1,1,1,1), 0.04))

func fade_out():
	set_modulate(lerp(get_modulate(), Color(0,0,0,1), 0.04))

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if not fade:
		fade_in()
	elif fade:
		fade_out()
	pass


func _on_main_menu_actioned(item):
	if item.get("name") == "NewGame":
		$StartTimer.start()
		fade = true
	if item.get("name") == "Options":
		options.emit()
	if item.get("name") == "Quit":
		quit.emit()
	pass # Replace with function body.


func _on_start_timer_timeout():
	newgame.emit()
	pass # Replace with function body.
