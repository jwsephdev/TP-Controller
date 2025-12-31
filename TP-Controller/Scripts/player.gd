class_name Player extends CharacterBody3D

@export_category("Movement")
@export var player_standspeed :float  = 8.0
@export var player_crouchspeed :float = 4.0

@export_category("Transitions")
@export var lerp_speed :float= 10.0

@export_category("Camera")
@export var cam_sens :float= 0.1

@export_category("Crouching")
@export var mount_pos_crouch :Vector3= Vector3(0,-0.5,0)
@export var springlength_crouch :float= 2.0

@export_category("Standing")
@export var springlength_stand :float= 5.0
@export var mount_pos_stand :Vector3= Vector3(0,0.5,0)

var playerSpeed :float
var direction = Vector3.ZERO
var is_crouching:bool = false

const JUMP_VELOCITY :float= 4.5

@onready var visuals: Node3D = $playerVisuals
@onready var camera_mount: Node3D = $cameraMount
@onready var camera: Camera3D = $cameraMount/cameraSpringarm/camera
@onready var camera_springarm: SpringArm3D = $cameraMount/cameraSpringarm

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
		playerSpeed = player_crouchspeed
		
		camera_mount.position = lerp(camera_mount.position, mount_pos_crouch, delta*lerp_speed)
		camera_springarm.spring_length = lerp(camera_springarm.spring_length, springlength_crouch, delta*lerp_speed)
		
		player_crouching_col.disabled = false
		player_standing_col.disabled = true
		
		player_crouching_mesh.show()
		player_standing_mesh.hide()
	else:
		playerSpeed = player_standspeed
		
		camera_mount.position = lerp(camera_mount.position, mount_pos_stand, delta*lerp_speed)
		camera_springarm.spring_length = lerp(camera_springarm.spring_length, springlength_stand, delta*lerp_speed)
		
		player_crouching_col.disabled = true
		player_standing_col.disabled = false
		
		player_crouching_mesh.hide()
		player_standing_mesh.show()
	
	if Input.is_action_pressed("Crouch"):
		is_crouching = true
	
	if !uncrouch_checker.is_colliding():
		if is_crouching and !Input.is_action_pressed("Crouch"):
			is_crouching = false

	
func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _input(event: InputEvent) -> void:
	camera_controls(event)

func _physics_process(delta: float) -> void:
	$fpslabel.text = "fps: " + str(Engine.get_frames_per_second())
	
	if not is_on_floor():
		velocity.y -= 9.8 * delta

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		
	var input_dir := Input.get_vector("Left", "Right", "Forward", "Backward")
	var movement := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	direction = lerp(direction,(transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(),delta*lerp_speed)
	if movement:
		visuals.look_at(position + movement)
	if is_on_floor():	
		if direction:
			velocity.x = direction.x * playerSpeed
			velocity.z = direction.z * playerSpeed
		else:
			velocity.x = lerp(velocity.x, 0.0, delta*5.0)
			velocity.z = lerp(velocity.x, 0.0, delta*5.0)
	else:
			velocity.x = lerp(velocity.x, direction.x * playerSpeed, delta*5.0)
			velocity.z = lerp(velocity.z, direction.z * playerSpeed, delta*5.0)
		
	crouching(delta)
	move_and_slide()
