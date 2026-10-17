extends Control

@onready var tutorial: Control = $Tutorial
@onready var recipes: Control = $Recipes
@onready var ingredients: Control = $Ingredients
@onready var cooking: Control = $Cooking

@onready var tutorial_btn: Button = $Bookmarks/TutorialBtn
@onready var recipes_btn: Button = $Bookmarks/RecipesBtn
@onready var ingredients_btn: Button = $Bookmarks/IngredientsBtn
@onready var cooking_btn: Button = $Bookmarks/CookingBtn

@onready var page_to_btn: Dictionary = {
	tutorial : tutorial_btn,
	recipes : recipes_btn,
	ingredients : ingredients_btn,
	cooking : cooking_btn,
}

var current_page: Control
var unlocked_recipes: Dictionary = {}

func open() -> void:
	if current_page:
		current_page.visible = false
		page_to_btn[current_page].position.y = -40

	current_page = recipes
	current_page.visible = true
	get_parent().visible = true
	page_to_btn[current_page].position.y = -100

func close() -> void:
	get_parent().visible = false
	
func switch_page(page: Control) -> void:
	page_to_btn[current_page].position.y = -40
	current_page.visible = false
	current_page = page
	current_page.visible = true
	page_to_btn[current_page].position.y = -100

func unlock_knowledge(
	potion: Cons.RECIPE,
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
	
	var recipe: Control = recipes.get_child(0).get_child(potion + 1)
	var label: Label = recipe.get_node("Potion")
	label.text = Utility.get_keyname(potion, Cons.RECIPE)

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
	if event is InputEventKey and event.pressed and not event.echo \
		and event.keycode == KEY_SPACE and visible == false:
			open()

func _on_cooking_btn_pressed() -> void:
	switch_page(cooking)

func _on_ingredients_btn_pressed() -> void:
	switch_page(ingredients)

func _on_recipes_btn_pressed() -> void:
	switch_page(recipes)

func _on_tutorial_btn_pressed() -> void:
	switch_page(tutorial)

class RecipeKnowledge:
	var ingredients_count = 1
	var ingredients: bool = false
	var temperature: bool = false
	var strir_pattern: bool = false
	
	func _init(_ingredients_count: int) -> void:
		ingredients_count = _ingredients_count
	
	func print() -> void:
		print(ingredients)
		print(temperature)
		print(strir_pattern)
