class_name Player extends CharacterBody3D


@export var cam_sens = 0.1
@export var playerSpeed = 8.0
@export var lerp_speed = 10.0


@export var camera_pos_standing:Vector3 = Vector3(0,0.5,0)
@export var camera_pos_crouching:Vector3 = Vector3(0,-0.5,0)

var direction = Vector3.ZERO
var is_crouching:bool = false

const JUMP_VELOCITY = 4.5

@onready var visuals: Node3D = $playerVisuals
@onready var camera_mount: Node3D = $cameraMount
@onready var camera: Camera3D = $cameraMount/cameraSpringarm/camera

@onready var player_standing_mesh: MeshInstance3D = $playerVisuals/player_standingMesh
@onready var player_crouching_mesh: MeshInstance3D = $playerVisuals/player_crouchingMesh
@onready var player_crouching_col: CollisionShape3D = $player_crouchingCol
@onready var player_standing_col: CollisionShape3D = $player_standingCol
@onready var uncrouch_checker: RayCast3D = $uncrouch_checker


func camera_controls(event):
	if event is InputEventMouseMotion:
		rotate_y(deg_to_rad(-event.relative.x) * cam_sens)
		visuals.rotate_y(deg_to_rad(event.relative.x) * cam_sens)
		camera_mount.rotate_x(deg_to_rad( -event.relative.y) * cam_sens)
		camera_mount.rotation.x = clamp(camera_mount.rotation.x, deg_to_rad(-70), deg_to_rad(15))

func crouching(delta):
	if is_crouching:
		camera_mount.position = lerp(camera_mount.position,camera_pos_crouching, delta*lerp_speed)
		player_crouching_col.disabled = false
		player_standing_col.disabled = true
		
		player_crouching_mesh.show()
		player_standing_mesh.hide()
	else:
		camera_mount.position = lerp(camera_mount.position,camera_pos_standing, delta*lerp_speed)
		player_crouching_col.disabled = true
		player_standing_col.disabled = false
		
		player_crouching_mesh.hide()
		player_standing_mesh.show()
	
	if Input.is_action_pressed("Crouch"):
		is_crouching = true
	
	if !uncrouch_checker.is_colliding():
		if is_crouching and !Input.is_action_pressed("Crouch"):
			is_crouching = false

func _input(event: InputEvent) -> void:
	camera_controls(event)
	
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta: float) -> void:
	$fpslabel.text = "fps: " + str(Engine.get_frames_per_second())
	
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	
	direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction:
		
		visuals.look_at(position + direction)
		velocity.x = direction.x * playerSpeed
		velocity.z = direction.z * playerSpeed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	crouching(delta)
	move_and_slide()
