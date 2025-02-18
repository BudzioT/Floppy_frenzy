extends Control

@export var address: String = "127.0.0.1"
@export var port: int = 8910
@export var max_players: int = 6

var peer


func _ready() -> void:
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	
	multiplayer.connected_to_server.connect(_server_connected)
	multiplayer.connection_failed.connect(_server_connection_fail)
	multiplayer.server_disconnected.connect(_server_disconnected)

func _process(delta: float) -> void:
	pass

	
func _player_connected(id: int):
	print("Player connected " + str(id))

func _player_disconnected(id: int):
	print("Player disconnected " + str(id))

func _server_connected():
	print("Connected to the server")
	
func _server_connection_fail():
	print("Connection to server failed")

func _server_disconnected():
	print("Disconnected from the server")


func _on_host_button_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_server(port, max_players)
	if error != OK:
		print("Cannot host a server (" + error + ")")
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)
	print("Waiting for players...")

func _on_join_button_button_down() -> void:
	peer = ENetMultiplayerPeer.new()
	var error = peer.create_client(address, port)
	if error != OK:
		print("Couldn't connect to server (" + error + ")")
		return
	
	peer.get_host().compress(ENetConnection.COMPRESS_RANGE_CODER)
	multiplayer.set_multiplayer_peer(peer)	
