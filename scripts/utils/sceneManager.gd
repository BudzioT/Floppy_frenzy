extends Node3D

@export var player_scene: PackedScene


func _ready() -> void:
	var index: int = 0
	var spawns = get_tree().get_nodes_in_group("SpawnLocations")
	
	for player in GameManager.players:
		var current_player = player_scene.instantiate()
		add_child(current_player)
		
		var spawn_name = "Spawn" + str(index)
		var spawn_point = spawns.filter(func(spawn): return spawn.name == spawn_name)	
	
		if !spawn_point.is_empty():
			await get_tree().process_frame
			current_player.global_position = spawn_point[0].global_position
			
			var physical_body = current_player.get_node("Physical/Armature/Skeleton3D/Physical Bone Body")
			if physical_body:
				physical_body.global_position = spawn_point[0].global_position
				# Reset the velocity to prevent any initial physics impulses
				physical_body.linear_velocity = Vector3.ZERO
				physical_body.angular_velocity = Vector3.ZERO
			
			print("Spawning player at: ", spawn_point[0].global_position, " ppos ", current_player.global_position)
		else:
			print("spawn", spawn_point)
		index += 1
