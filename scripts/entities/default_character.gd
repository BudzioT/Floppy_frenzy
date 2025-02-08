extends CharacterBody3D

var target_velocity = Vector3.ZERO
@export var speed = 14

func _ready():
	$Skeleton3D/PhysicalBoneSimulator3D.physical_bones_start_simulation()

func _physics_process(delta: float) -> void:
	var dir = Vector3.ZERO
	if Input.is_action_pressed("move_forwards"):
		dir.z += 1
	if Input.is_action_pressed("move_backwards"):
		dir.z -= 1
	if Input.is_action_pressed("move_left"):
		dir.x -= 1
	if Input.is_action_pressed("move_right"):
		dir.x += 1
		
	if dir != Vector3.ZERO:
		dir = dir.normalized()
		
	target_velocity.x = dir.x * speed
	target_velocity.z = dir.z * speed
	
	velocity = target_velocity
	move_and_slide()
