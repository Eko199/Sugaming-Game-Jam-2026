extends Control

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return data is Node and data.is_in_group("ingredient")

func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	# Executes if _can_drop_data() = true
	print("dropped")
