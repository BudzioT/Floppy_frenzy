extends Node3D

@export var player_scene: PackedScene


func _ready() -> void:
	var index: int = 0
	var spawns = get_tree().get_nodes_in_group("SpawnLocations")
	
	# Spawn every player
	for player in GameManager.players:
		var current_player = player_scene.instantiate()
		current_player.name = str(GameManager.players[player].id)
		current_player.get_node("CameraPivot").name = str(GameManager.players[player].id)
		current_player.get_node("MultiplayerSynchronizer").set_multiplayer_authority(GameManager.players[player].id)
		add_child(current_player)
		
		# Get spawners and current spawner name
		var spawn_name = "Spawn" + str(index)
		var spawn_point = spawns.filter(func(spawn): return spawn.name == spawn_name)	
		
		# Try to spawn character	
		if !spawn_point.is_empty():
			await get_tree().process_frame
			
			# It sucks, but the player spawns at the wrong place, can't fix it, gotta adjust maps ; /
			current_player.global_position = spawn_point[0].global_position
		index += 1
