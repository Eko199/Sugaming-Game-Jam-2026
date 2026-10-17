extends Node 

const REC_ID: int = 0
const HEAT: int = 1
const STIR: int = 2
const PRICE: int = 3

var RECIPE: Dictionary[Array, Array] = {
	[Ingredient.TYPE.FIRE_WORM] : [
		Cons.RECIPE.FIRE_RESISTANCE, Vector2i(30, 70),
		Cons.STIR_PATTERN.ANY, 10
	]
}

func evaluate(ing: Array[Ingredient.TYPE], heat: int, stir: Cons.STIR_PATTERN):
	ing.sort()
	var properties: Array = RECIPE.get(ing, [])
	if properties.is_empty(): return {
		success = false, recipe_id = 0, money = 0, quality = Cons.QUALITY.FAIL,
	}
	var quality: Cons.QUALITY = (
		Cons.QUALITY.POOR + int(
			properties[HEAT].y > heat and properties[HEAT].x < heat
		) + int(
			stir == properties[STIR] or properties[STIR] == Cons.STIR_PATTERN.ANY
		)
	) as Cons.QUALITY
	
	return {
		success = true,
		recipe_id = properties[REC_ID],
		money = properties[PRICE],
		quality = quality,
	}
