extends RefCounted
## Pure presentation registry. No damage, targeting, resource or timing rules.
## M5 Lv40 roster: R=sword, A=burst mage, T=healer, U=universal.
const STYLE: Dictionary = {
	"U01":"ARCANE_BOLT", "U02":"BARRIER", "U03":"WARD", "U04":"AURA", "U05":"HEAL",
	"R01":"MELEE", "R02":"MELEE", "R03":"MELEE", "R05":"PARRY", "R06":"MELEE",
	"R07":"MELEE", "R08":"BARRIER",
	"A01":"FIREBALL", "A02":"FIRE_WAVE", "A03":"AURA", "A04":"FIRE_BEAM",
	"A05":"DISRUPT", "A06":"FIRE_LANCE", "A07":"FIREBALL",
	"T01":"HEAL", "T03":"PARTY_HEAL", "T04":"BARRIER", "T05":"BARRIER",
	"T06":"HEAL", "T09":"LIGHT_BOLT", "T10":"LIGHT_BOLT",
	"LS_REN_SWORD_V1":"MELEE",
	"LS_AKANE_MAGE_V1":"FIRE_LANCE",
	"LS_TSUMUGI_HEAL_V1":"PARTY_HEAL",
	"regular":"ARCANE_BOLT", "burn":"FIREBALL", "ward":"BARRIER", "regen":"HEAL"
}
const PROJECTILES: Array[String] = [
	"ARCANE_BOLT", "FIREBALL", "FIRE_WAVE", "FIRE_BEAM", "FIRE_LANCE", "LIGHT_BOLT"
]
const SUPPORT: Array[String] = ["BARRIER", "WARD", "AURA", "HEAL", "PARTY_HEAL", "DISRUPT"]

static func style_for(card_id: String) -> String:
	return str(STYLE.get(card_id, "NONE"))

## Pure visual enrichment: production CastingReleased omits spell/target IDs.
## Never mutate authoritative events or add these fields to replay commands.
static func annotate_releases(events: Array, prior_casts: Dictionary) -> Array:
	var result: Array = events.duplicate(true)
	for event: Dictionary in result:
		if str(event.get("kind","")) not in ["CastingReleased","LastSpellReleased"]: continue
		var detail: Dictionary = event.get("details",{})
		var cast: Dictionary = prior_casts.get(str(detail.get("casting_id","")),{})
		if not detail.has("spell_id") and cast.has("spell_id"): detail["spell_id"] = cast["spell_id"]
		if not detail.has("target_actor_id") and cast.has("target_snapshot"):
			detail["target_actor_id"] = str(cast["target_snapshot"].get("actor_id",""))
	return result

## Separate releases in a scheduler receipt must keep their own caster/style.
static func release_groups(events: Array) -> Array:
	var groups: Array = []
	var current: Array = []
	var has_release: bool = false
	for event: Dictionary in events:
		if str(event.get("kind","")) in ["CastingReleased","LastSpellReleased"]:
			if has_release:
				groups.append(current)
				current = []
			has_release = true
		current.append(event)
	if not current.is_empty(): groups.append(current)
	return groups

static func is_projectile(style: String) -> bool:
	return PROJECTILES.has(style)

static func is_support(style: String) -> bool:
	return SUPPORT.has(style)

## Delayed Full Chant/Last Spell releases are emitted by a later command.
## Prioritize the authoritative released spell id over the current UI card.
static func receipt_style(command: Dictionary, events: Array) -> String:
	var id: String = str(command.get("_visual_card_id", ""))
	for event: Dictionary in events:
		if str(event.get("kind","")) in ["CastingReleased", "LastSpellReleased"]:
			var released: String = str(event.get("details",{}).get("spell_id", ""))
			if not released.is_empty():
				id = released
	return style_for(id)

static func projectile_texture(style: String) -> Texture2D:
	match style:
		"FIREBALL", "FIRE_WAVE", "FIRE_LANCE":
			return preload("res://addons/kenney_particle_pack/fire_01.png")
		"FIRE_BEAM":
			return preload("res://addons/kenney_particle_pack/flare_01.png")
		"LIGHT_BOLT":
			return preload("res://addons/kenney_particle_pack/star_02.png")
		_:
			return preload("res://addons/kenney_particle_pack/magic_01.png")

static func tint(style: String) -> Color:
	match style:
		"FIREBALL", "FIRE_WAVE", "FIRE_BEAM", "FIRE_LANCE":
			return Color("#FF873C")
		"LIGHT_BOLT", "HEAL", "PARTY_HEAL":
			return Color("#B4EDCE")
		"BARRIER", "WARD":
			return Color("#6DCBFF")
		_:
			return Color("#AFACFF")
