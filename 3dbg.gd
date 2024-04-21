extends Node3D
var tilt : String = "low"
var scroll_command : String = "mid"
var scroll_speed : Vector3 = Vector3.ZERO
const SCROLL_SPEED_LOW = -0.1
const SCROLL_SPEED_MID = -0.2
const SCROLL_SPEED_HIGH = -0.4
const ANGLE_LOW = Vector3(40.0, 0.0, 0.0)
const ANGLE_TOP = Vector3.ZERO
@onready var bg_plane : MeshInstance3D = $bg_plane
@onready var camera : Camera3D = $Camera

# Called when the node enters the scene tree for the first time.
func _ready():
	set_bg_material(bg_plane, "res://art/bg1.png")
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if tilt == "top_down":
		camera.rotation_degrees = camera.rotation_degrees.lerp(ANGLE_TOP, .1)
	elif tilt == "low":
		camera.rotation_degrees = camera.rotation_degrees.lerp(ANGLE_LOW, .01)
	if scroll_command == "low":
		scroll_speed = scroll_speed.lerp(Vector3(SCROLL_SPEED_LOW * delta, 0.0, 0.0), .1)
	elif scroll_command == "mid":
		scroll_speed = scroll_speed.lerp(Vector3(SCROLL_SPEED_MID * delta, 0.0, 0.0), .1)
	elif scroll_command == "high":
		scroll_speed = scroll_speed.lerp(Vector3(SCROLL_SPEED_HIGH * delta, 0.0, 0.0), .1)
	bg_plane.translate(scroll_speed)
	# Infinite scrolling by jumping the entire 3D plane UP by 4.0 Y units
	# (I can't believe this works)
	if bg_plane.position.y < -2.0:
		bg_plane.translate(Vector3(4.0, 0.0, 0.0))

func set_bg_material(background_surface : MeshInstance3D, texture_path : String):
	var image = Image.new()
	image.load(texture_path)
	var texture = ImageTexture.create_from_image(image)
	if background_surface.material_override:
		background_surface.material_override.albedo_texture = texture
		# TODO May have to redefine the tiling? is there a way to fit relative to 256x256?
		background_surface.material_override.uv1_scale = Vector3(10.0, 1.0, 1.0)

func set_tilt(tilt_name):
	tilt = tilt_name

func set_speed(speed_name):
	scroll_command = speed_name
