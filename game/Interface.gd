extends Control
var lives_displayed : int
var bombs_displayed : int

# Called when the node enters the scene tree for the first time.
func _ready():
	var difficulty_texture = load("res://art/Normal.tres")
	var difficulty_icon = TextureRect.new()
	difficulty_icon.set_texture(difficulty_texture)
	$VBoxContainer/DifficultyContainer.add_child(difficulty_icon)
	lives_displayed = ($VBoxContainer/LivesContainer.get_child_count() - 1)
	bombs_displayed = ($VBoxContainer/BombsContainer.get_child_count() - 1)
	update_lives()
	update_bombs()
	set_power(GameState.player_power)
	set_graze(GameState.player_graze)

func _process(delta):
	pass

func update_lives():
	if lives_displayed < GameState.player_lives:
		for i in range(GameState.player_lives - lives_displayed):
			var life_texture = load("res://art/LifeIcon.tres")
			var life_icon = TextureRect.new()
			life_icon.set_texture(life_texture)
			life_icon.set_modulate(Color.RED)
			life_icon.set_stretch_mode(3)
			$VBoxContainer/LivesContainer.add_child(life_icon)
	elif lives_displayed > GameState.player_lives:
		for i in range(lives_displayed - GameState.player_lives):
			var LifeIcons = $VBoxContainer/LivesContainer.get_children()
			LifeIcons[-1].queue_free()
	lives_displayed = ($VBoxContainer/LivesContainer.get_child_count() - 1)

func update_bombs():
	if bombs_displayed < GameState.player_bombs:
		for i in range(GameState.player_bombs - bombs_displayed):
			var bomb_texture = load("res://art/LifeIcon.tres")
			var bomb_icon = TextureRect.new()
			bomb_icon.set_texture(bomb_texture)
			bomb_icon.set_stretch_mode(3)
			$VBoxContainer/BombsContainer.add_child(bomb_icon)
	elif bombs_displayed > GameState.player_bombs:
		for i in range(bombs_displayed - GameState.player_bombs):
			var BombIcons = $VBoxContainer/BombsContainer.get_children()
			BombIcons[-1].queue_free()
	bombs_displayed = ($VBoxContainer/BombsContainer.get_child_count() - 1)

func set_power(power):
	$VBoxContainer/PowerContainer/PowerValue.text = str(power)

func set_graze(graze):
	$VBoxContainer/GrazeContainer/GrazeValue.text = str(graze)
