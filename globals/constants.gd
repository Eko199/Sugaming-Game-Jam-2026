extends Node

enum STIR_PATTERN {
	LEFT, RIGHT, ZIG_ZAG, NONE
}

const DESCRIPTIONS: PackedStringArray = [
	'blah', 'blah'
]

enum QUALITY {
	FAIL, POOR, GOOD, EXCELLENT
}

enum RECIPE {
	REC1
}

enum DEBUFF {
	
}

const MAX_INGREDIENTS: int = 3

const INGRIDIENT_TEXTURE: Dictionary[Ingredient.TYPE, String] = {
	Ingredient.TYPE.FIRE_WORM : 'res://icon.svg',
	Ingredient.TYPE.COLD_MINTLEAF : 'res://icon.svg',
}
