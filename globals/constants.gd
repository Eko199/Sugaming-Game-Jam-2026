extends Node

# Enums
enum STIR_PATTERN {
	CLOCKWISE, COUNTERCLOCKWISE, ANY
}

enum QUALITY {
	FAIL, POOR, GOOD, EXCELLENT
}

enum RECIPE {
	SHRINKING, STRENGTH, HEALING, FIRE_RESISTANCE, WATER_CONTROL,
	NIGHT_VISION, JUMPING_POWER, CLONING
}

enum DEBUFF {
	COLOR_BLINDNESS, SPEECH_MISUNDERSTANDING,
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

const REQUEST_LINES: Array = [
	[
		"QUICK! A %s potion, NOW!",
		"%s potion! Hurry, hurry!",
		"No time! %s potion, fast!",
		"The dragon's coming! %s potion!!",
	],
	[
		"Please give me a %s potion!",
		"One %s potion, please.",
		"I need a %s potion.",
		"Got a %s potion for me?",
	],
	[
		"Whenever you're ready, a %s potion please~",
		"No rush, friend. One %s potion.",
		"Take your time, I'd like a %s potion.",
		"Ah, a %s potion would be lovely.",
	],
]

const QUALITY_MULT: PackedFloat32Array = [
	0.0, 1.0, 1.5, 2.0
]

# Gameplay constants
const MAX_INGREDIENTS: int = 3
const ROUND_TIME: int = 300
const PATIENCE_MIN: int = 10
const PATIENCE_MAX: int = 30
const CUSTOMER_GAP: float = 1.0
const RECIPE_DIFFICULTY_FALLOFF: float = 2.0
const EASY_RECIPE_MIN_WEIGHT: float = 0.35
