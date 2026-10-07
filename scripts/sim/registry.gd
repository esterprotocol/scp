class_name Registry
extends RefCounted

# Stable integer identities. Ids are monotonic and never reused, so a stale
# reference can never silently point at a different entity.

var _kinds: Dictionary = {} # id -> kind (StringName)
var _next_id := 1

func create(kind: StringName) -> int:
	var id := _next_id
	_next_id += 1
	_kinds[id] = kind
	return id

func destroy(id: int) -> bool:
	return _kinds.erase(id)

func exists(id: int) -> bool:
	return _kinds.has(id)

func kind_of(id: int) -> StringName:
	return _kinds.get(id, &"")

func ids_of(kind: StringName) -> Array[int]:
	var result: Array[int] = []
	for id: int in _kinds:
		if _kinds[id] == kind:
			result.append(id)
	result.sort()
	return result

func reset() -> void:
	_kinds.clear()
	_next_id = 1
