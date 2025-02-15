extends Node3D

var ragdoll_mode: bool = false

var jump_strength: int = 70
var speed = 50
var damping = 0.9

# Jump stuff
@onready var jump_timer = $Physical/JumpTimer
var can_jump: bool = true
var walking: bool = false
var on_floor: bool = false
@onready var on_floor_left = $"Physical/Armature/Skeleton3D/Physical Bone LLeg2/OnFloorLeft"
@onready var on_floor_right = $"Physical/Armature/Skeleton3D/Physical Bone RLeg2/OnFloorRight"

# Some ragdoll things
@export var spring_stiffness: float = 4000.0
@export var spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0
# Skeleton nodes for ragdoll adujstements
@onready var physical_skeleton: Skeleton3D = $Physical/Armature/Skeleton3D
@onready var animated_skeleton: Skeleton3D = $Animated/Armature/Skeleton3D
@onready var physical_body: PhysicalBone3D = $"Physical/Armature/Skeleton3D/Physical Bone Body"
var physical_bones: Array = []

@onready var camera_pivot = $CameraPivot
@onready var animation_tree = $Animated/AnimationTree

var saved_delta: float = 0.0

func _ready() -> void:
	# Activate ragdoll, get all bones
	physical_skeleton.physical_bones_start_simulation()
	physical_bones = physical_skeleton.get_children().filter(func(x): return x is PhysicalBone3D)
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ragdoll"):
		ragdoll_mode = !ragdoll_mode
		
func _process(delta: float) -> void:
	var r = clamp((camera_pivot.rotation.x * 2) / PI * 2.1, -1, 1)
	
func _physics_process(delta: float) -> void:
	saved_delta = delta
	if not ragdoll_mode:
		walking = false
		var dir = Vector3.ZERO
		if Input.is_action_pressed("move_forwards"):
			dir += animated_skeleton.global_transform.basis.z
			walking = true
		if Input.is_action_pressed("move_backwards"):
			dir -= animated_skeleton.global_transform.basis.z
			walking = true
		if Input.is_action_pressed("move_left"):
			dir += animated_skeleton.global_transform.basis.x
			walking = true
		if Input.is_action_pressed("move_right"):
			dir -= animated_skeleton.global_transform.basis.x
			walking = true
		dir = dir.normalized()
		
		physical_body.linear_velocity += dir * speed * delta
		physical_body.linear_velocity *= Vector3(damping, 1, damping)
		
		on_floor = false
		if on_floor_left.is_colliding():
			for i in on_floor_left.get_collision_count():
				if on_floor_left.get_collision_normal(i).y > 0.5:
					on_floor = true
					break
		if not on_floor:
			for i in on_floor_right.get_collision_count():
				if on_floor_right.get_collision_normal(i).y > 0.5:
					on_floor = true
					break
		
		if Input.is_action_pressed("jump"):
			if on_floor and can_jump:
				physical_body.linear_velocity.y += jump_strength
				jump_timer.start()
				can_jump = false
				
		animated_skeleton.rotation.y = camera_pivot.rotation.y
		

func _on_skeleton_3d_skeleton_updated() -> void:
	if not ragdoll_mode:
		for bone: PhysicalBone3D in physical_bones:
			var current_transform: Transform3D = physical_skeleton.global_transform * physical_skeleton.get_bone_global_pose(bone.get_bone_id())
			var target_transform: Transform3D = animated_skeleton.global_transform * animated_skeleton.get_bone_global_pose(bone.get_bone_id())
			var diff: Basis = (target_transform.basis * current_transform.basis.inverse())
			var torque = hookes_law(diff.get_euler(), bone.angular_velocity, spring_stiffness, spring_damping)
			torque = torque.limit_length(max_angular_force)
			
			bone.angular_velocity += torque * saved_delta
			
func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffnes: float, damping: float) -> Vector3:
	return (stiffnes * displacement) - (damping * current_velocity)
	


func _on_jump_timer_timeout() -> void:
	can_jump = true
