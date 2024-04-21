extends Node3D
var tilt : String = "top_down"
var scroll_command : String = "mid"
var scroll_speed : Vector3 = Vector3.ZERO
const SCROLL_SPEED_LOW = Vector3(-0.1 * delta, 0.0, 0.0)
const SCROLL_SPEED_MID = Vector3(-0.2 * delta, 0.0, 0.0)
const SCROLL_SPEED_HIGH = Vector3(-0.4 * delta, 0.0, 0.0)
const ANGLE_LOW = Vector3(50.0, 0.0, 0.0)
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
		camera.rotation_degrees = camera.rotation_degrees().lerp(ANGLE_TOP, .1)
	elif tilt == "low":
		camera.rotation_degrees = camera.rotation_degrees().lerp(ANGLE_LOW, .1)
	if scroll_command == "low":
		scroll_speed = scroll_speed.lerp(SCROLL_SPEED_LOW, .1)
	elif scroll_command == "mid":
		scroll_speed = scroll_speed.lerp(SCROLL_SPEED_MID, .1)
	elif scroll_command == "high":
		scroll_speed = scroll_speed.lerp(SCROLL_SPEED_HIGH, .1)
	bg_plane.transform(scroll_speed)

func set_bg_material(background_surface : MeshInstance3D, texture_path : String):
	var image = Image.new()
	image.load(texture_path)
	var texture = ImageTexture.create_from_image(image)
	if background_surface.material_override:
		background_surface.material_override.albedo_texture = texture
		# TODO May have to redefine the tiling? is there a way to fit relative to 256x256?
		background_surface.material_override.uv1_scale = Vector3(10.0, 1.0, 1.0)


func tilt():
	tilt_x = not tilt_x
	pass # Replace with function body.
