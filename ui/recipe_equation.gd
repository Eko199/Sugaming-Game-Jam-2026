extends HBoxContainer

func setup() -> void:
	var count = $Ingredients.get_child_count()
	var icon_size = Vector2(120, 120) if count == 1 else Vector2(60, 60)
	print(icon_size)

	for i in range(count):
		var rect = $Ingredients.get_child(i)
		rect.custom_minimum_size = icon_size
