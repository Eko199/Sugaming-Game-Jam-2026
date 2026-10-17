extends Control

func open() -> void:
	visible = true

func close() -> void:
	visible = false

func _on_almanac_pressed() -> void:
	open()

func _on_exit_pressed() -> void:
	close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible == true:
		close()
