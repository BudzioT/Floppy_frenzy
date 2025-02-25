extends Node3D

@export var mouse_sensitivity: float = 0.1
@export var target: Node3D

@export var physical_skeleton: Skeleton3D
@onready var spring_arm = $SpringArm3D

var lock_mouse: bool = false


func _ready() -> void:
	pass

func _physics_process(_delta: float) -> void:
	for bone in physical_skeleton.get_children():
		if bone is PhysicalBone3D:
			spring_arm.add_excluded_object(bone.get_rid())
	if target:
		global_position = lerp(global_position, target.global_position, 0.5)
			
func _input(event: InputEvent) -> void:
	# Locking camera
	if Input.is_action_just_pressed("pause"):
		lock_mouse = false
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and (event.button_index == MOUSE_BUTTON_LEFT or event.button_index == MOUSE_BUTTON_RIGHT) and event.is_pressed():
		lock_mouse = true
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
	# Rotate it, don't allow too far up/down movement
	if event is InputEventMouseMotion and lock_mouse:
		rotation_degrees.y -= mouse_sensitivity * event.relative.x 
		rotation_degrees.x -= mouse_sensitivity * event.relative.y
		rotation_degrees.x = clamp(rotation_degrees.x, -45, 45)
