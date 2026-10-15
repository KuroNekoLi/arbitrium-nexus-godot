extends RefCounted
## Pure presentation mapping. Unknown Domain events are deliberately not animated.
const KINDS: Dictionary = {
	"CastingStarted":"CAST_START", "CastingReleased":"CAST_RELEASE",
	"CastingInterrupted":"INTERRUPT", "CastingInvalidated":"CAST_INVALID",
	"LastSpellCommitted":"LAST_START", "LastSpellReleased":"LAST_RELEASE",
	"LastSpellInvalidated":"LAST_INVALID", "LastSpellDestabilizedDelayed":"LAST_DELAY",
	"LastSpellDestabilizedWeakened":"LAST_WEAKEN", "ActorExhausted":"EXHAUSTED",
	"ActorIncapacitated":"INCAPACITATED", "GuardCoverageRegistered":"GUARD",
	"AttackTargetRedirected":"PROTECT", "FocusWardGranted":"FOCUS_WARD",
	"BreakTriggered":"BREAK", "ExposedApplied":"EXPOSED", "ComboExecuted":"COMBO",
	"ReactionSkipped":"REACTION_SKIPPED", "ReactionExecuted":"REACTION",
	"EnemyActionCancelled":"ENEMY_CANCELLED", "DamageTrace":"DAMAGE"
}
static func map_events(events: Array) -> Array[Dictionary]:
	var cues: Array[Dictionary] = []
	for event: Dictionary in events:
		var kind: String = str(event["kind"])
		var detail: Dictionary = event["details"]
		var cue: String = str(KINDS.get(kind,""))
		if kind == "BattleOutcomeEvaluated" and detail.get("outcome","ONGOING") != "ONGOING":
			cue = str(detail["outcome"])
		if cue.is_empty(): continue
		cues.append({"id":str(event["command_id"])+":"+str(event["event_seq"]),
			"kind":cue,"event_seq":event["event_seq"],"detail":detail.duplicate(true),
			"actor_id":str(detail.get("caster_id",detail.get("actor_id",detail.get("source_actor_id","Boss"))))})
	return cues
