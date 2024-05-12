extends Node3D
var tilt : String = "low"
var scroll_command : String = "mid"
var scroll_speed : Vector3 = Vector3.ZERO
const SCROLL_SPEED_LOW = -0.1
const SCROLL_SPEED_MID = -0.2
const SCROLL_SPEED_HIGH = -0.4
const ANGLE_LOW = Vector3(30.0, 0.0, 0.0)
const ANGLE_TOP = Vector3.ZERO
@onready var bg_plane : MeshInstance3D = $bg_plane
@onready var camera : Camera3D = $Camera

func _ready():
	set_bg_material(bg_plane, GameState.data["stage"][GameState.current_stage]["stage_texture"])

# Manages the tilt and scroll speed every frame
# Resets the 3dbg's position to create infinite scrolling
func _process(delta):
	if tilt == "top_down":
		camera.rotation_degrees = camera.rotation_degrees.lerp(ANGLE_TOP, .01)
	elif tilt == "low":
		camera.rotation_degrees = camera.rotation_degrees.lerp(ANGLE_LOW, .01)
	if scroll_command == "low":
		scroll_speed = scroll_speed.lerp(Vector3(SCROLL_SPEED_LOW * delta, 0.0, 0.0), .1)
	elif scroll_command == "mid":
		scroll_speed = scroll_speed.lerp(Vector3(SCROLL_SPEED_MID * delta, 0.0, 0.0), .1)
	elif scroll_command == "high":
		scroll_speed = scroll_speed.lerp(Vector3(SCROLL_SPEED_HIGH * delta, 0.0, 0.0), .1)
	bg_plane.translate(scroll_speed)
	if bg_plane.position.y < -2.0:
		bg_plane.translate(Vector3(4.0, 0.0, 0.0))

# Sets the texture on the flat plane 3d object projected onto the gamefield subviewport
func set_bg_material(background_surface : MeshInstance3D, texture_path : String):
	var image = Image.new()
	image.load(texture_path)
	var texture = ImageTexture.create_from_image(image)
	if background_surface.material_override:
		background_surface.material_override.albedo_texture = texture
		# TODO May have to redefine the tiling? is there a way to fit relative to 256x256?
		background_surface.material_override.uv1_scale = Vector3(10.0, 1.0, 1.0)

# Assigns a string value to tilt: "top_down" (camera perpindicular), "low" (camera pans up)
func set_tilt(tilt_name):
	tilt = tilt_name

# Assigns a string value to scroll_command: "low" 25%, "mid" 50%, "high" 100% speed
func set_scroll(scroll_name):
	scroll_command = scroll_name
