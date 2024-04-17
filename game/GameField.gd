extends SubViewport

var player_instance
var boss_instance


func _ready():
	var player = load("res://game/player.tscn")
	player_instance = player.instantiate()
	add_child(player_instance)
	var boss = load("res://game/boss.tscn")
	boss_instance = boss.instantiate()
	add_child(boss_instance)
	pass # Replace with function body.
