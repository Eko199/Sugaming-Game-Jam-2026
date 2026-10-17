extends Node

# Enums
enum STIR_PATTERN {
	LEFT, RIGHT, ZIG_ZAG, NONE
}

enum QUALITY {
	FAIL, POOR, GOOD, EXCELLENT
}

enum RECIPE {
	REC1
}

enum DEBUFF {
	
}

# General information
## TODO: Add actual sprites
const INGRIDIENT_TEXTURE: PackedStringArray = [
	'res://icon.svg',
	'res://icon.svg',
	'res://icon.svg',
	'res://icon.svg',
	'res://icon.svg',
	'res://icon.svg',
]

# TODO: ГОШО ПЛЗ НАПРАВИ ДЕСКРИПШЪНИ!!!
const DESCRIPTIONS: PackedStringArray = [
	'blah',
	'blah',
	'blah',
	'blah',
	'blah',
	'blah',
]

# Gameplay constants
const MAX_INGREDIENTS: int = 3
