extends TextureRect

func _get_drag_data(_at_position: Vector2) -> Variant:
	print("hello")
	set_drag_preview(duplicate())
	return self

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	# check if cauldron
	print("fail")
	return false

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	# Executes if _can_drop_data() = true
	print("dropped")
