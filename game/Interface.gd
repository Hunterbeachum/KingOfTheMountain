extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	var difficulty_texture = load("res://art/Normal.tres")
	var difficulty_icon = TextureRect.new()
	difficulty_icon.set_texture(difficulty_texture)
	$VBoxContainer/DifficultyContainer.add_child(difficulty_icon)
	for i in range(GameState.STARTING_LIVES):
		var life_texture = load("res://art/LifeIcon.tres")
		var life_icon = TextureRect.new()
		life_icon.set_texture(life_texture)
		life_icon.set_stretch_mode(3)
		$VBoxContainer/LivesContainer.add_child(life_icon)
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func update_lives():
	var life_texture = load("res://art/LifeIcon.tres")
	var life_icon = TextureRect.new()
	life_icon.set_texture(life_texture)
	life_icon.set_stretch_mode(3)
	$VBoxContainer/LivesContainer.add_child(life_icon)
	pass
