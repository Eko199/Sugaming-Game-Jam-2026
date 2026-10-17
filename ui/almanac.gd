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
var recipes_dict: Dictionary = {}

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
	var recipe_row: Control = recipes.get_child(0).get_child(potion)
	var unlocked_recipe: RecipeKnowledge = unlocked_recipes[potion]

	if ingredient:
		unlocked_recipe.ingredients = true
		var ingredients_container = recipe_row.get_node("Ingredients")
		for i in range(unlocked_recipe.ingredients_count):
			var ingredient_container = ingredients_container.get_child(i)
			var ingredient_num = recipes_dict[potion][0][i]
			ingredient_container.texture = load(Cons.INGRIDIENT_TEXTURE[ingredient_num])
			
	if temperature:
		unlocked_recipe.temperature = true
	if strir_pattern:
		unlocked_recipe.strir_pattern = true

	var label: Label = recipe_row.get_node("Potion")
	label.text = Utility.get_keyname(potion, Cons.RECIPE)
	
func process_potion_result(result: Dictionary) -> void:
	if not result.success:
		return
		
	unlock_knowledge(result["recipe_id"], true, result["correct_temperature"], result["correct_stir"])

func _ready() -> void:
	for rcp_ingredients: Array in Recipe.RECIPE:
		var ingredients_count = len(rcp_ingredients)
		var knowledge: RecipeKnowledge = RecipeKnowledge.new(ingredients_count)
		var potion = Recipe.RECIPE[rcp_ingredients][0]
		unlocked_recipes[potion] = knowledge
		
		var recipe_row = recipes.get_child(0).get_child(potion)
		var ingredients_container = recipe_row.get_node("Ingredients")
		for i in range(ingredients_count, ingredients_container.get_child_count()):
			ingredients_container.get_child(i).queue_free()
		
		recipes_dict[potion] = [rcp_ingredients, Recipe.RECIPE[rcp_ingredients][1], Recipe.RECIPE[rcp_ingredients][2]]
	
	Event.potion_served.connect(process_potion_result)
		
func _on_almanac_pressed() -> void:
	open()

func _on_exit_pressed() -> void:
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
