extends Node

## Returns the current main scene
var scene: MainScene:
	get: return get_tree().current_scene if is_inside_tree() else null

## Give an enum and key to get the name of the key
func get_keyname(key: int, enu: Dictionary) -> String:
	return (enu.find_key(key) as String).replace('_', ' ').capitalize()
