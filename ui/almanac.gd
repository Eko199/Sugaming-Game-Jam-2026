extends Control

@onready var tutorial: Control = $Tutorial
@onready var recipes: Control = $Recipes
@onready var ingredients: Control = $Ingredients
@onready var cooking: Control = $Cooking

var current_page: Control
var unlocked_recipes: Dictionary = {}

func open() -> void:
	if current_page:
		current_page.visible = false

	current_page = recipes
	current_page.visible = true
	visible = true

func close() -> void:
	visible = false
	
func switch_page(page: Control) -> void:
	current_page.visible = false
	current_page = page
	current_page.visible = true

func unlock_knowledge(
	potion: Ingredient.TYPE,
	ingredient: bool,
	temperature: bool,
	strir_pattern: bool
) -> void:
	if ingredient:
		unlocked_recipes[potion].ingredients = true
	if temperature:
		unlocked_recipes[potion].temperature = true
	if strir_pattern:
		unlocked_recipes[potion].strir_pattern = true

func _ready() -> void:
	for rcp_ingredients: Array in Recipe.RECIPE:
		var ingredients_count = len(rcp_ingredients)
		var knowledge: RecipeKnowledge = RecipeKnowledge.new(ingredients_count)
		var potion = Recipe.RECIPE[rcp_ingredients][0]
		unlocked_recipes[potion] = knowledge

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

func _on_recipes_btn_pressed() -> void:
	switch_page(recipes)

func _on_tutorial_btn_pressed() -> void:
	switch_page(tutorial)

class RecipeKnowledge:
	var ingredients: Array = [0]
	var temperature: bool = false
	var strir_pattern: bool = false
	
	func _init(ingredients_count: int) -> void:
		ingredients.resize(ingredients_count)
		ingredients.fill(0)
	
	func print() -> void:
		print(ingredients)
		print(temperature)
		print(strir_pattern)
