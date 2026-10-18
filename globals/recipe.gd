extends Node 

const REC_ID: int = 0
const HEAT: int = 1
const STIR: int = 2
const PRICE: int = 3

var RECIPE: Dictionary[Array, Array] = {
	[Ingredient.TYPE.GNOME_HAIR] : [
		Cons.RECIPE.SHRINKING, Vector2i(10, 55),
		Cons.STIR_PATTERN.ANY, 10
	],
	[Ingredient.TYPE.EXPANDING_BEANS] : [
		Cons.RECIPE.ENLARGEMENT, Vector2i(60, 100),
		Cons.STIR_PATTERN.CLOCKWISE, 15
	],
	[Ingredient.TYPE.UNICORN_TEARS, Ingredient.TYPE.STAR_FLOWER] : [
		Cons.RECIPE.HEALING, Vector2i(10, 90),
		Cons.STIR_PATTERN.ANY, 15
	],
	[Ingredient.TYPE.FIRE_WORM, Ingredient.TYPE.FROSTY_MINT] : [
		Cons.RECIPE.FIRE_RESISTANCE, Vector2i(0, 40),
		Cons.STIR_PATTERN.ANY, 20
	],
	[Ingredient.TYPE.FROSTY_MINT, Ingredient.TYPE.UNICORN_TEARS] : [
		Cons.RECIPE.WATER_CONTROL, Vector2i(0, 30),
		Cons.STIR_PATTERN.COUNTERCLOCKWISE, 25
	],
	[Ingredient.TYPE.EXPANDING_BEANS, Ingredient.TYPE.STAR_FLOWER] : [
		Cons.RECIPE.JUMPING_POWER, Vector2i(60, 80),
		Cons.STIR_PATTERN.CLOCKWISE, 30
	],
	[Ingredient.TYPE.GNOME_HAIR, Ingredient.TYPE.UNICORN_TEARS,
	 Ingredient.TYPE.EXPANDING_BEANS] : [
		Cons.RECIPE.CLONING, Vector2i(5, 25),
		Cons.STIR_PATTERN.ANY, 50
	],
	[Ingredient.TYPE.FIRE_WORM, Ingredient.TYPE.EXPANDING_BEANS,
	 Ingredient.TYPE.STAR_FLOWER] : [
		Cons.RECIPE.RAGE, Vector2i(70, 90),
		Cons.STIR_PATTERN.COUNTERCLOCKWISE, 50
	]
}

func evaluate(ing: Array[Ingredient.TYPE], heat: int, stir: Cons.STIR_PATTERN):
	ing.sort()
	var properties: Array = RECIPE.get(ing, [])
	if properties.is_empty(): return {
		success = false,
		recipe_id = 0,
		money = 0,
		ingredient_count = 0,
		quality = Cons.QUALITY.FAIL,
		correct_temperature = false,
		correct_stir = false
	}
	var quality: Cons.QUALITY = (
		Cons.QUALITY.POOR + int(
			properties[HEAT].y >= heat and properties[HEAT].x <= heat
		) + int(
			stir == properties[STIR] or properties[STIR] == Cons.STIR_PATTERN.ANY
		)
	) as Cons.QUALITY
	
	return {
		success = true,
		recipe_id = properties[REC_ID],
		money = properties[PRICE],
		ingredient_count = ing.size(),
		quality = quality,
		correct_temperature = properties[HEAT].y >= heat and properties[HEAT].x <= heat,
		correct_stir = stir == properties[STIR] or properties[STIR] == Cons.STIR_PATTERN.ANY
	}
