extends Node


func p(message: String, key: String = "") -> void:
	var identity: String
	if multiplayer.is_server():
		identity = "SERVER"
	else:
		identity = "CLIENT %d" % multiplayer.get_unique_id()

	if key.is_empty():
		print("[%s] %s" % [identity, message])
	else:
		print("[%s][%s] %s" % [identity, key, message])


func error(message: String, key: String = "") -> void:
	p("ERROR: %s" % message, key)