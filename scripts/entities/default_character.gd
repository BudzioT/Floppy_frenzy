extends Node3D

var ragdoll_mode: bool = false

# Some powers
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

# Grabbin
const GRAB_MODE: bool = 0
const PUNCH_MODE: bool = 1

var mode: bool = GRAB_MODE
var active_l_arm: bool = false
var active_r_arm: bool = false
var grab_l: bool = false
var grab_r: bool = false
var grabbed_obj = null

@onready var grab_l_joint = $Physical/GrabLeftJoint
@onready var grab_r_joint = $Physical/GrabRightJoint
@onready var physical_l_arm = $"Physical/Armature/Skeleton3D/Physical Bone LArm2"
@onready var physical_r_arm = $"Physical/Armature/Skeleton3D/Physical Bone RArm2"
@onready var grab_l_area = $"Physical/Armature/Skeleton3D/Physical Bone LArm2/LGrabArea"
@onready var grab_r_area = $"Physical/Armature/Skeleton3D/Physical Bone RArm2/RGrabArea"

var saved_delta: float = 0.0


func _ready() -> void:
	# Activate ragdoll, get all bones
	physical_skeleton.physical_bones_start_simulation()
	physical_bones = physical_skeleton.get_children().filter(func(x): return x is PhysicalBone3D)
	
func _input(event: InputEvent) -> void:
	if Input.is_action_just_pressed("ragdoll"):
		ragdoll_mode = !ragdoll_mode
		
	active_l_arm = Input.is_action_pressed("left_hand")
	active_r_arm = Input.is_action_pressed("right_hand")
	
	if (not active_l_arm and grab_l) or (ragdoll_mode and grab_l):
		grab_l = false
		grab_l_joint.node_a = NodePath()
		grab_l_joint.node_b = 	NodePath()
		grabbed_obj = null
	if (not active_r_arm and grab_r) or (ragdoll_mode and grab_r):
		grab_r = false
		grab_r_joint.node_a = NodePath()
		grab_r_joint.node_b = 	NodePath()
		grabbed_obj = null
		
func _process(delta: float) -> void:
	# Keep arms at direction of camera
	var r = clamp((camera_pivot.rotation.x * 2) / PI * 2.1, -1, 1)
	if active_l_arm or active_r_arm:
		animation_tree.set("parameters/Grab_dir/blend_position", r)
	else:
		animation_tree.set("parameters/Grab_dir/blend_position", 0)
	
func _physics_process(delta: float) -> void:
	saved_delta = delta
	
	# Allow walking and jumping when not beaten down
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
		
		# Velocity stuff to move
		physical_body.linear_velocity += dir * speed * delta
		physical_body.linear_velocity *= Vector3(damping, 1, damping)
		
		# Check if jump is allowed (player on floor)
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
				
		animation_tree.set("parameters/Walking/blend_amount", walking)
		
		# Rotate character based on camera rotation		
		animated_skeleton.rotation.y = camera_pivot.rotation.y
		

# Update skeleton for smooth active ragdoll
func _on_skeleton_3d_skeleton_updated() -> void:
	if not ragdoll_mode:
		for bone: PhysicalBone3D in physical_bones:
			if (not active_l_arm and bone.name.contains("LArm")) or (not active_r_arm and bone.name.contains("RArm")):
				continue
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


func _on_l_grab_area_body_entered(body: Node3D) -> void:
	if body is PhysicsBody3D and body.get_parent() != physical_skeleton:
		if active_l_arm and not grab_l:
			grab_l = true
			grab_l_joint.global_position = grab_l_area.global_position
			grab_l_joint.node_a = physical_l_arm.get_path()
			grab_l_joint.node_b = body.get_path()


func _on_r_grab_area_body_entered(body: Node3D) -> void:
	if body is PhysicsBody3D and body.get_parent() != physical_skeleton:
		if active_r_arm and not grab_r:
			grab_r = true
			grab_r_joint.global_position = grab_r_area.global_position
			grab_r_joint.node_a = physical_r_arm.get_path()
			grab_r_joint.node_b = body.get_path()
