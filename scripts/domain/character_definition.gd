@tool
class_name CharacterDefinition
extends Resource
## Static identity and configuration for one character.
## Runtime HP/MP/status and card instances live in battle state, never here.

@export var character_id: String = ""
@export var variant_id: String = ""
@export var name_key: String = ""
@export var display_zh: String = ""
@export var level: int = 40

@export var max_hp: int = 1
@export var max_mp: int = 0
@export var patk: int = 0
@export var matk: int = 0
@export var pdef: int = 0
@export var mdef: int = 0
@export var accuracy: int = 0
@export var evasion: int = 0
@export var crit_rate_bp: int = 0
@export var crit_bonus_bp: int = 0

@export var loadout: PackedStringArray = PackedStringArray()
@export var role_tags: PackedStringArray = PackedStringArray()
@export var appearance_path: String = ""
@export var passive: Dictionary = {}
@export var full_chant_passive: Dictionary = {}

@export var last_spell_id: String = ""
@export var last_spell_name_key: String = ""
@export var last_spell_mp_cost: int = 0
@export var last_spell_profile: Dictionary = {}
@export var last_spell_targeting: Dictionary = {}
@export var last_spell_effect: Dictionary = {}

## Returns a detached Dictionary matching the existing Lv40 Domain content API.
## Nested data is copied so battle assembly cannot mutate this shared Resource.
func to_actor_data() -> Dictionary:
	return {
		"character_id": character_id,
		"variant_id": variant_id,
		"name_key": name_key,
		"display_zh": display_zh,
		"level": level,
		"max_hp": max_hp,
		"max_mp": max_mp,
		"patk": patk,
		"matk": matk,
		"pdef": pdef,
		"mdef": mdef,
		"accuracy": accuracy,
		"evasion": evasion,
		"crit_rate_bp": crit_rate_bp,
		"crit_bonus_bp": crit_bonus_bp,
		"loadout": Array(loadout),
		"role_tags": Array(role_tags),
		"appearance_path": appearance_path,
		"passive": passive.duplicate(true),
		"full_chant_passive": full_chant_passive.duplicate(true),
		"last_spell_id": last_spell_id,
		"last_spell_name_key": last_spell_name_key,
		"last_spell_mp_cost": last_spell_mp_cost,
		"last_spell_profile": last_spell_profile.duplicate(true),
		"last_spell_targeting": last_spell_targeting.duplicate(true),
		"last_spell_effect": last_spell_effect.duplicate(true),
	}
