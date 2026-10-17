extends Control

@onready var tutorial: Control = $Tutorial
@onready var recipees: Control = $Recipees
@onready var ingredients: Control = $Ingredients
@onready var cooking: Control = $Cooking

var current_page: Control

func open() -> void:
	if current_page:
		current_page.visible = false

	current_page = recipees
	current_page.visible = true
	visible = true

func close() -> void:
	visible = false
	
func switch_page(page: Control) -> void:
	current_page.visible = false
	current_page = page
	current_page.visible = true

func _on_almanac_pressed() -> void:
	open()

func _on_exit_pressed() -> void:
	close()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and visible == true:
		close()

func _on_cooking_btn_pressed() -> void:
	switch_page(cooking)

func _on_ingredients_btn_pressed() -> void:
	switch_page(ingredients)

func _on_recipees_btn_pressed() -> void:
	switch_page(recipees)

func _on_tutorial_btn_pressed() -> void:
	switch_page(tutorial)
