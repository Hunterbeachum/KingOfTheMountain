class_name Menu extends VBoxContainer

@export var pointer: Node

func _ready():
	get_viewport().gui_focus_changed.connect(_on_focus_changed)
	configure_focus()

func _unhandled_input(event):
	if not visible: return
	
	get_viewport().set_input_as_handled()
	
	var item = get_focused_item()
	if is_instance_valid(item) and event.is_action_pressed("confirm"):
		item.focus_mode = Control.FOCUS_NONE
		SignalBus.menu_command.emit(item.get("name"))

# Called when the node enters the scene tree for the first time.
func get_items() -> Array[Control]:
	var items: Array[Control] = []
	for child in get_children():
		if not child is Control: continue
		if "Heading" in child.name: continue
		if "Divider" in child.name: continue
		items.append(child)
	return items

func configure_focus() -> void:
	var items = get_items()
	for i in items.size():
		var item: Control = items[i]
		
		item.focus_mode = Control.FOCUS_ALL
		
		item.focus_neighbor_left = item.get_path()
		item.focus_neighbor_right = item.get_path()
		
		if i == 0:
			item.focus_neighbor_top = item.get_path()
			item.focus_previous = item.get_path()
			item.grab_focus()
		else:
			item.focus_neighbor_top = items[i - 1].get_path()
			item.focus_previous = items[i - 1].get_path()
		
		if i == items.size() - 1:
			item.focus_neighbor_bottom = item.get_path()
			item.focus_next = item.get_path()
		else:
			item.focus_neighbor_bottom = items [i + 1].get_path()
			item.focus_next = items[i + 1].get_path()

func get_focused_item() -> Control:
	var item = get_viewport().gui_get_focus_owner()
	return item if item in get_children() else null

func update_selection() -> void:
	var item = get_focused_item()
	# Pointer is overlaid beneath each menu item
	if is_instance_valid(item) and is_instance_valid(pointer) and visible:
		item.z_index = pointer.z_index + 1
		pointer.size = item.get_texture().get_region().size
		pointer.global_position = Vector2(item.global_position.x, item.global_position.y)

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

### Signals

func _on_focus_changed(item: Control) -> void:
	if not item: return
	if not item in get_children(): return
	
	call_deferred("update_selection")
