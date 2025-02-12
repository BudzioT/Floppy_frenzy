extends Node3D

var ragdoll_mode: bool = false

@export var spring_stiffness: float = 4.0
@export var spring_damping: float = 80.0
@export var max_angular_force: float = 9999.0

@onready var physical_skeleton: Skeleton3D = $Physical/Armature/Skeleton3D
@onready var animated_skeleton: Skeleton3D = $Animated/Armature/Skeleton3D
var physical_bones: Array = []

var delta: float = 0.0

func _ready() -> void:
	# Activate ragdoll, get all bones
	physical_skeleton.physical_bones_start_simulation()
	physical_bones = physical_skeleton.get_children().filter(func(x): return x is PhysicalBone3D)

func _on_skeleton_3d_skeleton_updated() -> void:
	if not ragdoll_mode:
		for bone: PhysicalBone3D in physical_bones:
			var current_transform: Transform3D = physical_skeleton.global_transform * physical_skeleton.get_bone_global_pose(bone.get_bone_id())
			var target_transform: Transform3D = animated_skeleton.global_transform * animated_skeleton.get_bone_global_pose(bone.get_bone_id())
			var diff: Basis = (target_transform.basis * current_transform.basis.inverse())
			var torque = hookes_law(diff.get_euler(), bone.angular_velocity, spring_stiffness, spring_damping)
			torque = torque.limit_length(max_angular_force)
			
			bone.angular_velocity += torque * delta
			
func hookes_law(displacement: Vector3, current_velocity: Vector3, stiffnes: float, damping: float) -> Vector3:
	return (stiffnes * displacement) - (damping * current_velocity)
	
