extends RefCounted
## V3.5.4 pure DomainEvent → log row mapping. Every row carries the real
## event_seq (or a contiguous seq range for collapsed bookkeeping events).
## Text only restates fields already present in the event; nothing inferred.
const Mapper = preload("res://scripts/battle/presentation/battle_cue_mapper.gd")
const CATEGORY_COLORS: Dictionary = {
	"DAMAGE": Color("#FF7A6B"), "ACTION": Color("#F2C46D"), "CAST": Color("#C59BFF"),
	"DEFENSE": Color("#6FD6FF"), "STATUS": Color("#FFA65C"), "OUTCOME": Color("#FFE08A"),
	"RESOURCE": Color("#7FE0C8"), "INTENT": Color("#FF8FB8"), "GENERIC": Color("#7F93A3"),
}
const CUE_CATEGORY: Dictionary = {
	"CAST_START": "CAST", "CAST_RELEASE": "CAST", "CAST_INVALID": "CAST", "INTERRUPT": "CAST",
	"LAST_START": "CAST", "LAST_RELEASE": "CAST", "LAST_INVALID": "CAST",
	"LAST_DELAY": "CAST", "LAST_WEAKEN": "CAST",
	"GUARD": "DEFENSE", "PROTECT": "DEFENSE", "FOCUS_WARD": "DEFENSE",
	"REACTION": "DEFENSE", "REACTION_SKIPPED": "DEFENSE", "ENEMY_CANCELLED": "DEFENSE",
	"EXHAUSTED": "STATUS", "INCAPACITATED": "STATUS", "BREAK": "STATUS",
	"EXPOSED": "STATUS", "COMBO": "ACTION", "VICTORY": "OUTCOME", "DEFEAT": "OUTCOME",
}

## Resource-ledger events wrap their payload in core_event.event.details.
static func _core_details(detail: Dictionary) -> Dictionary:
	var core: Variant = detail.get("core_event", {})
	if core is Dictionary and core.get("event", {}) is Dictionary:
		var inner: Variant = core.get("event", {}).get("details", {})
		if inner is Dictionary:
			return inner
	return {}

static func _targets(intent: Dictionary, name_of: Callable) -> String:
	var names: PackedStringArray = []
	for id: Variant in intent.get("target_ids", []):
		names.append(name_of.call(str(id)))
	return ", ".join(names)

## translate: Callable(key) -> String; name_of: Callable(actor_id) -> String;
## skill_of: optional Callable(skill_id) -> String (falls back to BATTLE_<SKILL_ID>).
static func rows_for(events: Array, translate: Callable, name_of: Callable,
		skill_of: Callable = Callable()) -> Array:
	var rows: Array = []
	for event: Dictionary in events:
		var seq: int = int(event.get("event_seq", -1))
		var kind: String = str(event.get("kind", ""))
		var detail: Dictionary = event.get("details", {})
		var command_id: String = str(event.get("command_id", ""))
		var row: Dictionary = {"seq": seq, "seq_end": seq, "kind": kind, "category": "GENERIC",
			"text": "", "command_id": command_id}
		var core: Dictionary = _core_details(detail)
		var intent: Dictionary = detail.get("public_intent", {}) if detail.get("public_intent", {}) is Dictionary else {}
		if kind == "SPCostReservedOnly" and core.has("actor_id") and core.has("ap_paid") and core.has("mp_cost"):
			row["category"] = "RESOURCE"
			row["text"] = translate.call("BATTLE_LOG_COST") % [
				name_of.call(str(core["actor_id"])), int(core["ap_paid"]), int(core["mp_cost"])]
		elif kind == "PlayerResourcesClosed" and core.has("ap_remaining") and core.has("rp_created"):
			row["category"] = "RESOURCE"
			row["text"] = translate.call("BATTLE_LOG_PHASE_CLOSED") % [
				int(core["ap_remaining"]), int(core["rp_created"])]
		elif kind == "EnemyActionDeclared" and intent.has("skill_id") and intent.has("enemy_id"):
			var skill_id: String = str(intent["skill_id"])
			var skill_name: String = skill_of.call(skill_id) if skill_of.is_valid() \
				else translate.call("BATTLE_" + skill_id.to_upper())
			row["category"] = "INTENT"
			row["text"] = translate.call("BATTLE_LOG_ENEMY_DECLARED") % [
				name_of.call(str(intent["enemy_id"])), skill_name, _targets(intent, name_of)]
		elif kind == "BossIntentCommitted" and intent.has("enemy_id"):
			row["category"] = "INTENT"
			row["text"] = translate.call("BATTLE_LOG_INTENT_COMMITTED") % name_of.call(str(intent["enemy_id"]))
		elif kind == "ReactionWindowOpened":
			row["category"] = "DEFENSE"
			row["text"] = translate.call("BATTLE_LOG_REACTION_OPEN")
		elif kind == "HPDamageApplied" and detail.has("amount") and detail.has("recipient_id"):
			row["category"] = "DAMAGE"
			row["text"] = translate.call("BATTLE_LOG_DAMAGE") % [
				name_of.call(str(detail["recipient_id"])), int(detail["amount"])]
		elif kind == "PlayerActionSettled" and detail.has("actor_id"):
			row["category"] = "ACTION"
			row["text"] = translate.call("BATTLE_LOG_ACTION") % name_of.call(str(detail["actor_id"]))
		else:
			var cue: String = str(Mapper.KINDS.get(kind, ""))
			if kind == "BattleOutcomeEvaluated" and str(detail.get("outcome", "ONGOING")) != "ONGOING":
				cue = str(detail["outcome"])
			if not cue.is_empty() and cue != "DAMAGE":
				row["category"] = str(CUE_CATEGORY.get(cue, "GENERIC"))
				row["text"] = translate.call("BATTLE_CUE_" + cue)
		if row["category"] == "GENERIC":
			# Collapse adjacent bookkeeping events of the SAME command into one
			# honest seq range; batching therefore never changes the result.
			if not rows.is_empty() and rows[-1]["category"] == "GENERIC" and int(rows[-1]["seq_end"]) == seq - 1 \
					and str(rows[-1]["command_id"]) == command_id:
				rows[-1]["seq_end"] = seq
				rows[-1]["count"] = int(rows[-1].get("count", 1)) + 1
				continue
			row["text"] = translate.call("BATTLE_EVENT_GENERIC")
			row["count"] = 1
		rows.append(row)
	return rows

static func seq_label(row: Dictionary) -> String:
	if int(row["seq_end"]) != int(row["seq"]):
		return "#%d–%d" % [int(row["seq"]), int(row["seq_end"])]
	return "#%d" % int(row["seq"])

static func plain(row: Dictionary) -> String:
	return seq_label(row) + " · " + str(row["text"])
