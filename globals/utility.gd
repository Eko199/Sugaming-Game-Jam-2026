extends Node

## Give an enum and key to get the name of the key
func get_keyname(key: int, enu: Dictionary) -> String:
	return (enu.find_key(key) as String).replace('_', ' ').capitalize()
