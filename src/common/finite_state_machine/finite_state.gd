@tool
class_name FiniteState
extends Resource

signal state_change_requested(next: FiniteState)

## Base class every state in a card graph descends from. An exported property
## typed to this (or a subclass) is treated as a graph EDGE (a successor pin);
## any other exported property is treated as inline DATA on the node.
const STATE_BASE_CLASS := "FiniteState"

var _context: StateContext = null


func change_state(next: FiniteState) -> void:
	state_change_requested.emit(next)


## Called by the machine when this state becomes active. Wires up the run
## _context, then invokes the subclass hook. SEALED — subclasses override
## _on_enter(), never this, so there is no super.enter() to forget.
func enter(run_context: StateContext) -> void:
	_context = run_context
	_on_enter()


## Override to run logic when the state begins. `_context` is already populated;
## read the agent and blackboard off it. Takes no args — nothing to forward.
func _on_enter() -> void:
	pass


func tick(delta: float) -> void:
	_on_tick(delta)


func _on_tick(_delta: float) -> void:
	pass


func exit() -> void:
	_on_exit()


func _on_exit() -> void:
	pass

## ----------- Editor ---------------


## Property descriptors for every exported successor (an edge in the card graph).
## The export's NAME is the branch label (e.g. "on_empty"); its current value —
## read with `get(name)` — is the connected next state, or null if unwired.
##
## Pure introspection: subclasses NEVER override this. Declaring a typed export
## like `@export var on_empty: Action` is all that is required to gain a pin.
func get_successor_properties() -> Array[Dictionary]:
	var successors: Array[Dictionary] = []
	for property in get_property_list():
		if _is_state_reference_property(property):
			successors.append(property)
	return successors


## Property descriptors for every exported NON-successor value — the inline
## fields you populate on a node (ints, strings, target filters, ...).
func get_data_properties() -> Array[Dictionary]:
	var data: Array[Dictionary] = []
	for property in get_property_list():
		if not _is_exported_script_var(property):
			continue
		if _is_state_reference_property(property):
			continue
		data.append(property)
	return data


static func _is_exported_script_var(property: Dictionary) -> bool:
	var usage: int = property["usage"]
	var is_script_var := (usage & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0
	var is_stored := (usage & PROPERTY_USAGE_STORAGE) != 0
	return is_script_var and is_stored


static func _is_state_reference_property(property: Dictionary) -> bool:
	if not _is_exported_script_var(property):
		return false
	if property["type"] != TYPE_OBJECT:
		return false
	if property["hint"] != PROPERTY_HINT_RESOURCE_TYPE:
		return false
	return _class_derives_from_state(property["hint_string"])


## True when `class_to_check` is the state base class or any subclass of it,
## determined by walking the project's global class inheritance chain.
static func _class_derives_from_state(class_to_check: String) -> bool:
	if class_to_check.is_empty():
		return false
	if class_to_check == STATE_BASE_CLASS:
		return true
	var base_by_class := _build_base_lookup()
	var current := class_to_check
	while base_by_class.has(current):
		current = base_by_class[current]
		if current == STATE_BASE_CLASS:
			return true
	return false


static func _build_base_lookup() -> Dictionary:
	var base_by_class: Dictionary = { }
	for entry in ProjectSettings.get_global_class_list():
		base_by_class[entry["class"]] = entry["base"]
	return base_by_class


## Deep, isolated copy of the state graph reachable from this state. Shared
## successors (diamonds) stay shared in the copy, and cycles terminate, because
## each original is cloned at most once — tracked in `clones` ({original: copy}).
##
## Use this, NOT duplicate(true): duplicate(true) copies a shared/looping
## successor multiple times and can recurse forever on a cycle.
func clone_graph(clones: Dictionary = { }) -> FiniteState:
	if clones.has(self):
		return clones[self]

	# duplicate(false) copies data exports but leaves successor exports pointing
	# at the ORIGINAL next states; we overwrite each with its clone below.
	var copy: FiniteState = duplicate(false)
	clones[self] = copy

	for property in get_successor_properties():
		var next_state: FiniteState = get(property["name"])
		if next_state != null:
			copy.set(property["name"], next_state.clone_graph(clones))

	return copy
