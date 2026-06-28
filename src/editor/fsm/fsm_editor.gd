@tool
extends Control
## PROTOTYPE — finite-state-machine authoring view.
##
## Opens a FiniteStateMachine (.tres) and renders the graph reachable
## from its `entry_state`: data exports become inline fields, FiniteState-typed
## exports become labeled output pins. Clicking a pin's "+" instantiates a
## picked state script and wires it in; dragging between existing pins lets
## branches converge on one node (a diamond) or loop back (a cycle).
##
## Nodes are de-duplicated by instance identity, so diamonds and cycles draw a
## single node with multiple inbound edges rather than recursing forever.
##
## The runtime never sees this view — it only runs the saved FSM: a runner takes
## `entry_state` and follows each state's `state_change_requested` signal.
##
## The view is bound to a machine via `open_fsm(fsm, host)` (called by the editor
## plugin when "Edit Graph" is clicked) — never to a hardcoded path. `host` is the
## resource whose save persists the graph: the owning resource (e.g. a CardData)
## when the FSM is an embedded export, or the machine itself when inspected alone.

const IN_COLOR := Color(0.45, 0.78, 1.0)
const OUT_COLOR := Color(0.55, 1.0, 0.6)
const NODE_SPACING := Vector2(340.0, 70.0)
const ABSTRACT_BASES: PackedStringArray = ["FiniteState", "Action"]

@onready var _graph: GraphEdit = %GraphEdit
@onready var _status_label: Label = %StatusLabel
@onready var _host_label: Label = %HostLabel
@onready var _add_root_button: Button = %AddRootButton
@onready var _print_button: Button = %PrintButton
@onready var _save_button: Button = %SaveButton
@onready var _load_button: Button = %LoadButton
@onready var _delete_button: Button = %DeleteButton
@onready var _auto_save_check: CheckButton = %AutoSaveCheck
@onready var _unsaved_banner: PanelContainer = %UnsavedBanner

var _fsm: FiniteStateMachine
var _host_object: Object                  # the object that owns _fsm (Resource or Node)
var _is_dirty := false                    # graph mutated since the last successful save
var _node_by_state: Dictionary = {}        # FiniteState -> GraphNode
var _state_by_node_name: Dictionary = {}   # StringName -> FiniteState

# A "+" on a successor pin opens an async script picker; these remember the
# picker's current choices and the callback waiting on a pick.
var _picker: PopupMenu
var _picker_choices: Array = []
var _picker_callback: Callable


func _ready() -> void:
	_graph.connection_request.connect(_on_connection_request)
	_graph.disconnection_request.connect(_on_disconnection_request)
	_graph.delete_nodes_request.connect(_on_delete_nodes_request)
	_graph.connection_lines_curvature = 0
	_add_root_button.pressed.connect(_on_add_root_pressed)
	_print_button.pressed.connect(_on_print_pressed)
	_save_button.pressed.connect(_on_save_pressed)
	_delete_button.pressed.connect(_on_delete_selected_pressed)
	_auto_save_check.toggled.connect(_on_auto_save_toggled)
	# Loading is now driven by the inspector ("Edit Graph"), not a file path.
	_load_button.visible = false
	_update_unsaved_banner()
	_refresh_status()


# --- Binding -----------------------------------------------------------------

## Bind the view to an FSM and the resource that owns it, then draw its graph.
## Called by the editor plugin when the user clicks "Edit Graph" in the inspector.
func open_fsm(fsm: FiniteStateMachine, host: Object = null) -> void:
	_clear_graph()
	_fsm = fsm
	_host_object = host
	_host_label.text = _host_display_name()
	if _fsm != null and _fsm.entry_state != null:
		_rebuild_node(_fsm.entry_state, 0, {})
	# A freshly bound graph reflects what's on disk — start clean.
	_mark_clean()
	_refresh_status()


## Who owns the FSM currently open, for the toolbar — a CardData shows its file
## (e.g. "bridge.tres"), a scene node shows its node name (e.g. "Game"), and a
## machine inspected on its own shows its own file. Keeps it clear which graph
## you're editing when the view is otherwise empty.
func _host_display_name() -> String:
	if _host_object is Node:
		return String((_host_object as Node).name)
	if _host_object is Resource:
		var resource := _host_object as Resource
		if not resource.resource_path.is_empty():
			return resource.resource_path.get_file()
		if not resource.resource_name.is_empty():
			return resource.resource_name
		return "(unsaved FSM)"
	return "No FSM open"


# --- Node creation -----------------------------------------------------------

func _on_add_root_pressed() -> void:
	_open_state_picker(func(script_path: String) -> void:
		if _fsm == null:
			_fsm = FiniteStateMachine.new()
		var state: FiniteState = load(script_path).new()
		_fsm.entry_state = state
		_build_node_for(state, Vector2(40.0, 40.0))
		_mark_dirty()
		_refresh_status()
	)


func _on_add_successor_pressed(source_state: FiniteState, property_name: StringName) -> void:
	_open_state_picker(func(script_path: String) -> void:
		var new_state: FiniteState = load(script_path).new()
		source_state.set(property_name, new_state)
		var source_node: GraphNode = _node_by_state[source_state]
		_build_node_for(new_state, source_node.position_offset + NODE_SPACING)
		_draw_edge(source_state, property_name, new_state)
		_mark_dirty()
		_refresh_status()
	)


func _build_node_for(state: FiniteState, at_position: Vector2) -> GraphNode:
	if _node_by_state.has(state):
		return _node_by_state[state]

	# Build the node fully — title, rows, slots, position — BEFORE adding it to
	# the GraphEdit. Setting position_offset on a node already in the tree fires
	# GraphEdit._graph_element_moved before the element is registered, which
	# errors ("connections_layer is missing") and corrupts positioning/scroll.
	var node := GraphNode.new()
	node.name = "state_%d" % _node_by_state.size()
	node.title = _node_title(state)
	node.position_offset = at_position

	# Row 0: the single flow-in pin (any number of edges may land here).
	var in_label := Label.new()
	in_label.text = "● in"
	node.add_child(in_label)

	# Data exports become inline editable fields (no pins).
	for property in state.get_data_properties():
		node.add_child(_build_data_row(state, property))

	# Successor exports become one labeled output pin each.
	var successor_properties := state.get_successor_properties()
	var first_successor_row := node.get_child_count()
	var ordered_pin_names := PackedStringArray()
	for property in successor_properties:
		node.add_child(_build_successor_row(state, property))
		ordered_pin_names.append(property["name"])
	node.set_meta("pin_names", ordered_pin_names)

	# Slots: input on row 0; output on each successor row.
	node.set_slot(0, true, 0, IN_COLOR, false, 0, OUT_COLOR)
	for i in successor_properties.size():
		node.set_slot(first_successor_row + i, false, 0, IN_COLOR, true, 0, OUT_COLOR)

	_graph.add_child(node)
	_node_by_state[state] = node
	_state_by_node_name[node.name] = state

	return node


func _build_data_row(state: FiniteState, property: Dictionary) -> Control:
	var row := HBoxContainer.new()
	var name_label := Label.new()
	name_label.text = property["name"]
	name_label.custom_minimum_size.x = 110.0
	row.add_child(name_label)
	row.add_child(_build_value_editor(state, property))
	return row


func _build_value_editor(state: FiniteState, property: Dictionary) -> Control:
	var property_name: StringName = property["name"]
	match int(property["type"]):
		TYPE_BOOL:
			var check := CheckBox.new()
			check.button_pressed = state.get(property_name)
			check.toggled.connect(func(value: bool) -> void:
				state.set(property_name, value)
				_mark_dirty())
			return check
		TYPE_INT:
			var int_spin := SpinBox.new()
			int_spin.rounded = true
			int_spin.step = 1
			int_spin.min_value = -99999
			int_spin.max_value = 99999
			int_spin.value = state.get(property_name)
			int_spin.value_changed.connect(func(value: float) -> void:
				state.set(property_name, int(value))
				_mark_dirty())
			return int_spin
		TYPE_FLOAT:
			var float_spin := SpinBox.new()
			float_spin.step = 0.1
			float_spin.min_value = -99999
			float_spin.max_value = 99999
			float_spin.value = state.get(property_name)
			float_spin.value_changed.connect(func(value: float) -> void:
				state.set(property_name, value)
				_mark_dirty())
			return float_spin
		TYPE_STRING, TYPE_STRING_NAME:
			var line := LineEdit.new()
			line.custom_minimum_size.x = 140.0
			line.text = str(state.get(property_name))
			line.text_changed.connect(func(value: String) -> void:
				state.set(property_name, value)
				_mark_dirty())
			return line
		_:
			var unsupported := Label.new()
			unsupported.text = "(unsupported)"
			return unsupported


func _build_successor_row(state: FiniteState, property: Dictionary) -> Control:
	var row := HBoxContainer.new()

	var add_button := Button.new()
	add_button.text = "+"
	add_button.tooltip_text = "Create and connect a state on '%s'" % property["name"]
	add_button.pressed.connect(_on_add_successor_pressed.bind(state, property["name"]))
	row.add_child(add_button)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(spacer)

	var name_label := Label.new()
	name_label.text = "%s ●" % property["name"]
	row.add_child(name_label)

	return row


# --- Edges -------------------------------------------------------------------

func _draw_edge(source_state: FiniteState, property_name: StringName, target_state: FiniteState) -> void:
	var source_node: GraphNode = _node_by_state[source_state]
	var target_node: GraphNode = _node_by_state[target_state]
	var port := _output_port_for(source_node, property_name)
	if port < 0:
		return
	_graph.connect_node(source_node.name, port, target_node.name, 0)


func _output_port_for(node: GraphNode, property_name: StringName) -> int:
	var pin_names: PackedStringArray = node.get_meta("pin_names")
	return pin_names.find(property_name)


func _on_connection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var source_state: FiniteState = _state_by_node_name[from_node]
	var target_state: FiniteState = _state_by_node_name[to_node]
	var pin_names: PackedStringArray = _node_by_state[source_state].get_meta("pin_names")
	if from_port < 0 or from_port >= pin_names.size():
		return
	var property_name := pin_names[from_port]

	# A pin holds exactly one successor: drop any previous edge on it first.
	for connection in _graph.get_connection_list():
		if connection["from_node"] == from_node and connection["from_port"] == from_port:
			_graph.disconnect_node(from_node, from_port, connection["to_node"], connection["to_port"])

	source_state.set(property_name, target_state)
	_graph.connect_node(from_node, from_port, to_node, to_port)
	_mark_dirty()
	_refresh_status()


func _on_disconnection_request(from_node: StringName, from_port: int, to_node: StringName, to_port: int) -> void:
	var source_state: FiniteState = _state_by_node_name[from_node]
	var pin_names: PackedStringArray = _node_by_state[source_state].get_meta("pin_names")
	if from_port >= 0 and from_port < pin_names.size():
		source_state.set(pin_names[from_port], null)
	_graph.disconnect_node(from_node, from_port, to_node, to_port)
	_mark_dirty()
	_refresh_status()


# --- Deletion ----------------------------------------------------------------

## GraphEdit asks us to delete the selected nodes (Delete key); it doesn't remove
## anything itself, so we own the removal.
func _on_delete_nodes_request(node_names: Array) -> void:
	for node_name in node_names:
		_delete_state_node(node_name)
	_mark_dirty()
	_refresh_status()


## Toolbar "Delete Selected": same removal as the Delete key, for discoverability.
## Gathers the currently selected GraphNodes and deletes them.
func _on_delete_selected_pressed() -> void:
	var selected_node_names: Array[StringName] = []
	for state in _node_by_state.keys():
		var node: GraphNode = _node_by_state[state]
		if node.selected:
			selected_node_names.append(node.name)
	if selected_node_names.is_empty():
		print("[FSM] no node selected — click a node, then Delete Selected")
		return
	_on_delete_nodes_request(selected_node_names)


## Removes one node from both the graph and the data model: drops every edge
## touching it, clears any successor on OTHER states that pointed at it (so the
## saved graph keeps no dangling pointer), and clears entry_state if it was the
## start. Orphaned children stay as nodes for the user to rewire or delete.
func _delete_state_node(node_name: StringName) -> void:
	if not _state_by_node_name.has(node_name):
		return
	var state: FiniteState = _state_by_node_name[node_name]

	for connection in _graph.get_connection_list():
		if connection["from_node"] == node_name or connection["to_node"] == node_name:
			_graph.disconnect_node(connection["from_node"], connection["from_port"], connection["to_node"], connection["to_port"])

	for other_state in _node_by_state.keys():
		if other_state == state:
			continue
		for property in other_state.get_successor_properties():
			if other_state.get(property["name"]) == state:
				other_state.set(property["name"], null)

	if _fsm != null and _fsm.entry_state == state:
		_fsm.entry_state = null

	var node: GraphNode = _node_by_state[state]
	_graph.remove_child(node)
	node.queue_free()
	_node_by_state.erase(state)
	_state_by_node_name.erase(node_name)


# --- Save / load -------------------------------------------------------------

## Persists the graph by saving the host resource. When the FSM is an embedded
## export (host is e.g. a CardData), saving the host writes the sub-resource
## inline; when the machine is inspected on its own, host IS the machine.
func _on_save_pressed() -> void:
	_save_if_possible(false)


## Writes the graph to disk and clears the dirty state on success. `silent` mutes
## the console/warning chatter — used by auto-save, which fires on every edit and
## would otherwise spam (e.g. for scene-embedded graphs that can't save here).
## Returns true only when something was actually written.
func _save_if_possible(silent: bool) -> bool:
	if _fsm == null or _fsm.entry_state == null:
		if not silent:
			print("[FSM] nothing to save (no entry state)")
		return false
	var target := _save_target()
	for state: FiniteState in _node_by_state:
		var pos: Vector2 = _node_by_state[state].position_offset
		print("[FSM-DEBUG] set_meta graph_position=%s on %s" % [pos, state])
		state.set_meta("graph_position", pos)
	if target == null:
		if not silent:
			push_warning("[FSM] graph is embedded in a scene — save the scene (Ctrl+S) to persist it.")
		return false
	print("[FSM-DEBUG] saving %d node(s)" % _node_by_state.size())
	var error := ResourceSaver.save(target, target.resource_path)
	if error != OK:
		if not silent:
			push_error("[FSM] save failed (%d) for %s" % [error, target.resource_path])
		return false
	if not silent:
		print("[FSM] saved %s" % target.resource_path)
	_mark_clean()
	return true


## What to write to disk: the FSM's own file if it lives standalone; otherwise the
## owning resource (which embeds the FSM inline). A scene/node-embedded FSM has no
## saveable resource here — the user saves the owning scene instead.
func _save_target() -> Resource:
	if _fsm != null and _is_disk_path(_fsm.resource_path):
		return _fsm
	if _host_object is Resource and _is_disk_path((_host_object as Resource).resource_path):
		return _host_object
	return null


func _is_disk_path(path: String) -> bool:
	# Embedded sub-resources carry a "owner.tscn::Type_xxxx" path — not a real file.
	return not path.is_empty() and not path.contains("::")


# --- Dirty state / auto-save -------------------------------------------------

## Records that the in-memory graph diverged from disk: shows the banner, and if
## auto-save is on, writes immediately (silently) so the banner clears right back.
func _mark_dirty() -> void:
	_is_dirty = true
	_update_unsaved_banner()
	if _auto_save_check.button_pressed:
		_save_if_possible(true)


func _mark_clean() -> void:
	_is_dirty = false
	_update_unsaved_banner()


func _update_unsaved_banner() -> void:
	_unsaved_banner.visible = _is_dirty


## Turning auto-save on with edits already pending flushes them right away.
func _on_auto_save_toggled(is_on: bool) -> void:
	if is_on and _is_dirty:
		_save_if_possible(true)


## Rebuilds a node and everything reachable from it. `column_next_y` tracks the
## next free Y per depth so the layout stays tidy. De-dup by instance identity
## (in `_build_node_for`) makes this safe for diamonds and cycles.
func _rebuild_node(state: FiniteState, depth: int, column_next_y: Dictionary) -> void:
	if _node_by_state.has(state):
		return
	
	var x := 40.0 + depth * NODE_SPACING.x
	var y: float = column_next_y.get(depth, 40.0)
	column_next_y[depth] = y + NODE_SPACING.y
	var fallback = Vector2(x, y)
	var stored_pos: Vector2 = state.get_meta("graph_position", fallback)
	print("[FSM-DEBUG] load pos for %s: stored=%s fallback=%s" % [state, stored_pos, fallback])
	_build_node_for(state, stored_pos)

	for property in state.get_successor_properties():
		var next_state: FiniteState = state.get(property["name"])
		if next_state == null:
			continue
		_rebuild_node(next_state, depth + 1, column_next_y)
		_draw_edge(state, property["name"], next_state)


func _clear_graph() -> void:
	# Remove only the GraphNodes we created. A blanket sweep of get_children()
	# risks freeing GraphEdit's own internal layers (connection layer, minimap).
	_graph.clear_connections()
	for state in _node_by_state.keys():
		var node: GraphNode = _node_by_state[state]
		_graph.remove_child(node)
		node.queue_free()
	_node_by_state.clear()
	_state_by_node_name.clear()


# --- State script picker -----------------------------------------------------

func _open_state_picker(on_pick: Callable) -> void:
	if _picker == null:
		_picker = PopupMenu.new()
		add_child(_picker)
		_picker.id_pressed.connect(_on_picker_id_pressed)

	_picker_callback = on_pick
	_picker_choices = _pickable_state_scripts()
	_picker.clear()
	for i in _picker_choices.size():
		_picker.add_item(_picker_choices[i]["name"], i)

	_picker.position = DisplayServer.mouse_get_position()
	_picker.reset_size()
	_picker.popup()


func _on_picker_id_pressed(id: int) -> void:
	if id < 0 or id >= _picker_choices.size():
		return
	if _picker_callback.is_valid():
		_picker_callback.call(_picker_choices[id]["path"])


## Every concrete global class that derives from FiniteState, excluding
## the abstract bases you'd never instantiate directly.
func _pickable_state_scripts() -> Array:
	var choices: Array = []
	var base_by_class: Dictionary = {}
	for entry in ProjectSettings.get_global_class_list():
		base_by_class[entry["class"]] = entry["base"]

	for entry in ProjectSettings.get_global_class_list():
		var class_str: String = entry["class"]
		if ABSTRACT_BASES.has(class_str):
			continue
		if _derives_from_state(class_str, base_by_class):
			choices.append({ "name": class_str, "path": entry["path"] })

	choices.sort_custom(func(a, b): return a["name"] < b["name"])
	return choices


func _derives_from_state(class_str: String, base_by_class: Dictionary) -> bool:
	var current := class_str
	while base_by_class.has(current):
		current = base_by_class[current]
		if current == FiniteState.STATE_BASE_CLASS:
			return true
	return false


# --- Inspection / status -----------------------------------------------------

func _on_print_pressed() -> void:
	if _fsm == null or _fsm.entry_state == null:
		print("[FSM] (empty — add a starting state)")
		return
	print("[FSM] graph from entry state:")
	_print_state(_fsm.entry_state, {}, 1)


func _print_state(state: FiniteState, visited: Dictionary, depth: int) -> void:
	var indent := "  ".repeat(depth)
	if visited.has(state):
		print("%s↺ %s (already shown)" % [indent, _display_name(state)])
		return
	visited[state] = true
	print("%s%s" % [indent, _display_name(state)])
	for property in state.get_successor_properties():
		var next_state: FiniteState = state.get(property["name"])
		if next_state == null:
			print("%s  %s → (unconnected)" % [indent, property["name"]])
		else:
			print("%s  %s →" % [indent, property["name"]])
			_print_state(next_state, visited, depth + 2)


func _refresh_status() -> void:
	if _fsm == null or _fsm.entry_state == null:
		_status_label.text = "No starting state"
		return
	_status_label.text = "%d state(s)" % _node_by_state.size()


func _node_title(state: FiniteState) -> String:
	var name := _display_name(state)
	if _fsm != null and state == _fsm.entry_state:
		return "★ %s" % name
	return name


func _display_name(state: FiniteState) -> String:
	var script := state.get_script() as Script
	if script != null and not script.resource_path.is_empty():
		return script.resource_path.get_file().get_basename()
	return "state"
