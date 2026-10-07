class_name Reservations
extends RefCounted

# Exclusive, owner-tagged claims on any resource (cell, object, person, stock
# unit). Rule of the simulation: nobody acts on a resource without holding a
# live reservation for it. Reservations are all-or-nothing.

signal changed

const NO_OWNER := -1

var holders: Dictionary = {} # key (String) -> owner id (int)
var expiry: Dictionary = {} # key (String) -> last valid tick, optional

static func cell_key(cell: Vector2i) -> String:
	return "c:%d,%d" % [cell.x, cell.y]

static func object_key(id: int) -> String:
	return "o:%d" % id

func owner_of(key: String) -> int:
	return int(holders.get(key, NO_OWNER))

func holds(owner: int, key: String) -> bool:
	return owner_of(key) == owner

func keys_of(owner: int) -> Array[String]:
	var result: Array[String] = []
	for key: String in holders:
		if holders[key] == owner:
			result.append(key)
	result.sort()
	return result

# Returns {ok, reason, key, holder}. On failure nothing is reserved. A longer
# `until_tick` replaces the expiry; -1 keeps any existing expiry.
func reserve_all(owner: int, keys: Array, until_tick: int = -1) -> Dictionary:
	for key: String in keys:
		var holder := owner_of(key)
		if holder != NO_OWNER and holder != owner:
			return {"ok": false, "key": key, "holder": holder, "reason": "%s já reservado por %d." % [key, holder]}
	var added := false
	for key: String in keys:
		if not holders.has(key):
			added = true
		holders[key] = owner
		if until_tick >= 0:
			expiry[key] = until_tick
	if added:
		changed.emit()
	return {"ok": true, "key": "", "holder": owner, "reason": ""}

func release(owner: int, key: String) -> bool:
	if not holds(owner, key):
		return false
	holders.erase(key)
	expiry.erase(key)
	changed.emit()
	return true

func release_owner(owner: int) -> int:
	var count := 0
	for key: String in holders.keys():
		if holders[key] == owner:
			holders.erase(key)
			expiry.erase(key)
			count += 1
	if count > 0:
		changed.emit()
	return count

# Frees every reservation whose expiry tick has passed. Returns freed keys.
func expire(now: int) -> Array[String]:
	var freed: Array[String] = []
	for key: String in expiry.keys():
		if int(expiry[key]) < now:
			freed.append(key)
	freed.sort()
	for key in freed:
		holders.erase(key)
		expiry.erase(key)
	if not freed.is_empty():
		changed.emit()
	return freed

# Safety net and bug detector: keys whose owner no longer exists.
func orphans(is_alive: Callable) -> Array[String]:
	var result: Array[String] = []
	for key: String in holders:
		if not is_alive.call(int(holders[key])):
			result.append(key)
	result.sort()
	return result

func clear() -> void:
	if holders.is_empty():
		return
	holders.clear()
	expiry.clear()
	changed.emit()
