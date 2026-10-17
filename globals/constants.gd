extends Node

# Enums
enum STIR_PATTERN {
	CLOCKWISE, COUNTERCLOCKWISE, ANY
}

enum QUALITY {
	FAIL, POOR, GOOD, EXCELLENT
}

enum RECIPE {
	SHRINKING, STRENGTH, HEALING, FIRE_RESISTANCE,
	WATER_CONTROL, JUMPING_POWER, CLONING
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

const DESCRIPTIONS: PackedStringArray = [
	'A coarse, springy strand taken from a tiny garden gnome.',
	'Wiggly creatures that generate heat like crazy.',
	'Ice-cold leaves that can put you in an eternal slumber.',
	'Pure, rainbow liquid magic.',
	'Highly unstable magical legumes.',
	'A glowing celestial blossom that only blooms at midnight.',
]

const INGREDIENT_COLOR: PackedColorArray = [
	Color(0.72, 0.42, 0.18),
	Color(0.95, 0.22, 0.08),
	Color(0.45, 0.95, 0.80),
	Color(0.92, 0.55, 0.95),
	Color(0.40, 0.78, 0.15),
	Color(1.00, 0.82, 0.15),
]
const WATER_COLOR: Color = Color(0.40, 0.62, 0.85)
const WATER_TINT_STRENGTH: PackedFloat32Array = [0.0, 0.65, 0.85, 1.0]
const WATER_TINT_TIME: float = 0.4

const Z_WATER: int = 1
const Z_IN_CAULDRON: int = 2
const Z_CAULDRON_FRONT: int = 3
const Z_HELD: int = 4
const SINK_TIME: float = 0.45
const SINK_DEPTH: float = 70.0

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
const TEMP_DIAL_CHANGE: int = 5
const PERFECT_TIME_BONUS: float = 5.0
