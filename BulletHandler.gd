extends Path2D

var bullet_count = 1000000000
var remaining = bullet_count
@export var bullet_scene: PackedScene
@onready var bullet_path : PathFollow2D = $BulletPath
@export var speed = 300
var drawing_pattern = true
var patterns_dict = JSON.parse_string(FileAccess.get_file_as_string("res://game/bullet_pattern_library.json"))

func _ready():
	generate_pattern()

static func new_pattern(name: String):
	pass

func _process(delta):
	if drawing_pattern:
		bullet_path.progress += speed * delta
		if bullet_path.progress_ratio >= (1.0 - (1.0 / bullet_count) * remaining):
			remaining -= 1
			var bullet_spawn_location = bullet_path.position
			# var direction = bullet_spawn_location.angle_to_point($Player.position)
			# var direction_list = []
			var bullet = bullet_scene.instantiate()
			var bullet_velocity = Vector2(0.0, 0.0)
			bullet.position = bullet_spawn_location
			# bullet_velocity.rotated(n)
			bullet.linear_velocity = bullet_velocity
			add_child(bullet)
		if bullet_path.progress_ratio >= 1.0:
			get_tree().call_group("bullets", "set_linear_velocity", Vector2(0.0, 100.0))
			drawing_pattern = false
	pass

func generate_pattern():
	pass
