extends Node

# Game data
var data : Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://game/data.json"))

# Player properties
var player_position : Vector2 = Vector2(208.0, 440.0) # Player's position
var player_lives : int

# Boss properties
var boss_position : Vector2 = Vector2(0.0, 0.0)
var current_boss_pattern : String = "test_pattern_1"

# Pattern properties
var drawing_pattern : bool = false

# Stage properties
var current_stage : String = ""
var enemy_gamestate : Array = []

# Constants
const CENTERSCREEN = Vector2(180.0, 96.0)

