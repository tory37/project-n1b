extends Node

var _cards: Dictionary[String, CardData] = {}

func _ready() -> void:
	load_all_cards("res://resources/cards/")


func get_card(unique_id: String) -> CardData:
	if unique_id in _cards:
		return _cards[unique_id]
	else:
		push_error("Card with unique_id '%s' not found in registry!" % unique_id)
		return null


func load_all_cards(folder_path: String) -> void:
	var dir = DirAccess.open(folder_path)
	
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			# Ignore subfolders for this script (unless you want recursive loading)
			if not dir.current_is_dir():
				
				# THE EXPORT TRAP FIX: 
				# When you export a game, Godot converts .tres files to binary and adds .remap
				# We must strip that extension to load the file successfully in a built game.
				var clean_name = file_name.trim_suffix(".remap")
				
				# Check if it's actually a resource file
				if clean_name.ends_with(".tres") or clean_name.ends_with(".res"):
					var full_path = folder_path + clean_name
					
					# Load the resource
					var loaded_res = load(full_path)
					
					# Double check it's the right kind of resource before adding it
					if loaded_res is CardData:
						_cards[loaded_res.unique_id] = loaded_res
					else:
						push_warning("Found a .tres file that isn't CardData: " + full_path)
						
			# Move to the next file
			file_name = dir.get_next()
			
		print("Successfully loaded %s cards!" % _cards.size())
	else:
		push_error("Failed to open directory: " + folder_path)