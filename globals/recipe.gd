extends Node 

const REC_ID: int = 0
const HEAT: int = 1
const STIR: int = 2
const PRICE: int = 3

const HEAT_GRACE: int = 15
const RECIPE: Dictionary[Array, Array] = {
	[Constant.INGREDIENT.FIRE_WORM, Constant.INGREDIENT.COLD_MINTLEAF] : [Constant.RECIPE.REC1, Vector2i(30, 70), Constant.STIR_PATTERN.NONE, 10]
}

func evaluate(ing: Array[Constant.INGREDIENT], heat: int, stir: Constant.STIR_PATTERN):
	ing.sort()
	var properties: Array = RECIPE.get(ing, [])
	if properties.is_empty(): return {
		success = false, recipe_id = 0, money = 0, quality = Constant.QUALITY.FAIL,
	}
	var quality: Constant.QUALITY = (
		Constant.QUALITY.POOR + int(
			properties[HEAT].y > heat and properties[HEAT].x < heat
		) + int(
			stir == properties[STIR] or properties[STIR] == Constant.STIR_PATTERN.NONE
		)
	) as Constant.QUALITY
	
	return {
		success = true,
		recipe_id = properties[REC_ID],
		money = properties[PRICE],
		quality = quality,
	}
