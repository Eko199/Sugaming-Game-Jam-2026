extends Node

# Enums
enum STIR_PATTERN {
	CLOCKWISE, COUNTERCLOCKWISE, ANY, NONE
}

enum QUALITY {
	FAIL, POOR, GOOD, EXCELLENT
}

enum RECIPE {
	SHRINKING, ENLARGEMENT, HEALING, FIRE_RESISTANCE,
	WATER_CONTROL, JUMPING_POWER, CLONING
}

enum DEBUFF {
	SENSORY_DEPRIVATION, SOUND_IMPAIRMENT, ITEM_SHUFFLE
}

const SPOON_UPGRADES_PRICE: PackedInt32Array = [
	100,
	200
]

const SPOON_LEVEL_MULT: PackedFloat32Array = [
	1.0,
	1.5,
	2.0
]

const SPOONS_TEXTURE: PackedStringArray = [
	"res://textures/spoon.png",
	"res://textures/silver_spoon.png",
	"res://textures/golden_spoon.png"
]

# General information
const INGRIDIENT_TEXTURE: PackedStringArray = [
	'res://textures/gnome_hair.png',
	'res://textures/fireworm.png',
	'res://textures/frosty_mint.png',
	'res://textures/unicorn_tears.png',
	'res://textures/expanding_beans.png',
	'res://textures/star_flower.png',
]

const STIRRING_TEXTURES: PackedStringArray = [
	"res://textures/rotation_cw.png",
	"res://textures/rotation_ccw.png",
	"res://textures/rotations_both.png"
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
	Color(0.683, 0.555, 0.485, 1.0),
	Color(0.95, 0.498, 0.076, 1.0),
	Color(0.4, 0.85, 0.715, 1.0),
	Color(0.578, 0.551, 0.95, 1.0),
	Color(0.40, 0.78, 0.15),
	Color(1.00, 0.82, 0.15),
]

const QUALITY_MULT: PackedFloat32Array = [0.0, 1.0, 1.5, 2.0]
const WATER_TINT_STRENGTH: PackedFloat32Array = [0.0, 0.65, 0.85, 1.0]
const STIR_AMOUNTS: PackedFloat32Array = [2.0, 2.5, 3.0]

# Gameplay constants
const WATER_COLOR: Color = Color(0.40, 0.62, 0.85)
const WATER_TINT_TIME: float = 0.4
const WATER_DRAIN_TIME: float = 0.7
const WATER_REFILL_TIME: float = 0.9
const Z_WATER: int = 1
const Z_IN_CAULDRON: int = 2
const Z_CAULDRON_FRONT: int = 3
const Z_HELD: int = 4
const SINK_TIME: float = 0.45
const SINK_DEPTH: float = 70.0
const STIR_DEAD_ZONE: float = 0.2
const STIR_OUTER_LIMIT: float = 1.2
const STIR_MAX_STEP: float = PI / 2
const MAX_INGREDIENTS: int = 3
const ROUND_TIME: int = 30
const PATIENCE_MIN: int = 5
const PATIENCE_MAX: int = 30
const CUSTOMER_GAP: float = 2.0
const RECIPE_DIFFICULTY_FALLOFF: float = 2.0
const EASY_RECIPE_MIN_WEIGHT: float = 0.35
const TEMP_DIAL_CHANGE: int = 5
const PERFECT_TIME_BONUS_BASE: float = 2.0
const PERFECT_TIME_BONUS_PER_INGREDIENT: float = 1.0
const DEBUFF_FAILS: int = 1
const DEBUFF_TIME: int = 20
const REQUEST_REPEAT_PENALTY_RECENT: float = 0.5
const REQUEST_REPEAT_PENALTY_OLDER: float = 0.8

const SAVE_PATH: String = "user://save_data.cfg"
