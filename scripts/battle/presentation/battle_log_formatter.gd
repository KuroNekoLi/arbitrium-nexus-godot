extends RefCounted
## V3.5.4 pure DomainEvent → log row mapping. Every row carries the real
## event_seq (or a contiguous seq range for collapsed bookkeeping events).
## Text only restates fields already present in the event; nothing inferred.
const Mapper = preload("res://scripts/battle/presentation/battle_cue_mapper.gd")
const CATEGORY_COLORS: Dictionary = {
	"DAMAGE": Color("#FF7A6B"), "ACTION": Color("#F2C46D"), "CAST": Color("#C59BFF"),
	"DEFENSE": Color("#6FD6FF"), "STATUS": Color("#FFA65C"), "OUTCOME": Color("#FFE08A"),
	"GENERIC": Color("#7F93A3"),
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

## translate: Callable(key) -> String; name_of: Callable(actor_id) -> String.
static func rows_for(events: Array, translate: Callable, name_of: Callable) -> Array:
	var rows: Array = []
	for event: Dictionary in events:
		var seq: int = int(event.get("event_seq", -1))
		var kind: String = str(event.get("kind", ""))
		var detail: Dictionary = event.get("details", {})
		var command_id: String = str(event.get("command_id", ""))
		var row: Dictionary = {"seq": seq, "seq_end": seq, "kind": kind, "category": "GENERIC",
			"text": "", "command_id": command_id}
		if kind == "HPDamageApplied" and detail.has("amount") and detail.has("recipient_id"):
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
