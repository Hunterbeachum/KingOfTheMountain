extends Control

# Called when the node enters the scene tree for the first time.
func _ready():
	SignalBus.player_hit.connect(update_lives)
	SignalBus.update_ui.connect(update_ui)
	var difficulty_texture = load("res://art/Normal.tres")
	var difficulty_icon = TextureRect.new()
	difficulty_icon.set_texture(difficulty_texture)
	$VBoxContainer/DifficultyContainer.add_child(difficulty_icon)
	update_ui()

func _process(delta):
	pass

func update_ui() -> void:
	update_lives()
	update_bombs()
	update_power()
	update_graze()

func update_lives():
	var lives_displayed = ($VBoxContainer/LivesContainer.get_child_count() - 1)
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

func update_bombs():
	var bombs_displayed = ($VBoxContainer/BombsContainer.get_child_count() - 1)
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

func update_power():
	$VBoxContainer/PowerContainer/PowerValue.text = str(GameState.player_power)

func update_graze():
	$VBoxContainer/GrazeContainer/GrazeValue.text = str(GameState.player_graze)
