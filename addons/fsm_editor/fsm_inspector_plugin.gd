@tool
extends EditorInspectorPlugin
## Adds graph authoring to the inspector for finite-state machines.
##
## Two shapes are handled:
##   - a resource OR node exporting a FiniteStateMachine-typed property
##     (e.g. `@export var fsm: FiniteStateMachine` on CardData or the
##     game-manager Node): the default field is replaced by a combined picker +
##     "Edit FSM" button so the action reads as one unit with the field. The
##     button is disabled while the export is null — assign or create a machine
##     with the picker first (there's nothing to edit otherwise);
##   - a FiniteStateMachine inspected on its own (a standalone .tres
##     selected in the FileSystem): a plain "Edit FSM" button via _parse_begin.
##
## The button hands the FSM and its owning object to the EditorPlugin, which
## opens the bottom-panel graph view bound to that exact instance.

## Carries the FSM to edit and the object that owns it. `host` may be a Resource
## (embedded export) or a Node (scene export) or the machine itself; the view
## decides what to save from it.
signal edit_graph_requested(fsm: FiniteStateMachine, host: Object)

const FSM_CLASS := "FiniteStateMachine"


func _can_handle(object: Object) -> bool:
	# Nodes (e.g. the game-manager) export FSMs too, not just Resources.
	return object != null


func _parse_begin(object: Object) -> void:
	if object is FiniteStateMachine:
		var button := Button.new()
		button.text = "Edit FSM"
		button.pressed.connect(func() -> void:
			edit_graph_requested.emit(object, object))
		add_custom_control(button)


func _parse_property(object: Object, type: Variant.Type, name: String, hint_type: PropertyHint, hint_string: String, usage_flags: int, wide: bool) -> bool:
	if type == TYPE_OBJECT and hint_string == FSM_CLASS:
		var property_editor := FsmGraphProperty.new()
		property_editor.edit_requested.connect(func(fsm: FiniteStateMachine) -> void:
			edit_graph_requested.emit(fsm, object))
		add_property_editor(name, property_editor)
		# We fully own this property's editor now.
		return true
	return false


## A single inspector row for an FSM export: Godot's resource picker (New / Load /
## Clear, same as the default field) sitting beside an "Edit FSM" button, so the
## button is visually attached to the field it acts on. The button stays disabled
## while the export is null — there's no graph to open until one is assigned.
class FsmGraphProperty:
	extends EditorProperty

	signal edit_requested(fsm: FiniteStateMachine)

	const NO_FSM_HINT := "Assign or create an FSM with the picker first — there's no graph to edit yet."

	var _picker := EditorResourcePicker.new()
	var _button := Button.new()
	# Guards against the picker re-emitting while we push the stored value into it.
	var _is_syncing := false

	func _init() -> void:
		var row := HBoxContainer.new()

		_picker.base_type = FSM_CLASS
		_picker.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		_picker.resource_changed.connect(_on_resource_changed)
		row.add_child(_picker)

		_button.text = "Edit FSM"
		_button.pressed.connect(_on_edit_pressed)
		row.add_child(_button)

		add_child(row)

	func _update_property() -> void:
		_is_syncing = true
		_picker.edited_resource = get_edited_object().get(get_edited_property())
		_is_syncing = false
		_refresh_button_state()

	func _on_resource_changed(resource: Resource) -> void:
		_refresh_button_state()
		if _is_syncing:
			return
		emit_changed(get_edited_property(), resource)

	## Only an assigned machine is editable; an empty export has no graph to show.
	func _refresh_button_state() -> void:
		var has_fsm := _picker.edited_resource != null
		_button.disabled = not has_fsm
		_button.tooltip_text = "" if has_fsm else NO_FSM_HINT

	func _on_edit_pressed() -> void:
		var fsm := _picker.edited_resource as FiniteStateMachine
		if fsm == null:
			return  # Button is disabled when null; guard against a stray press.
		edit_requested.emit(fsm)
