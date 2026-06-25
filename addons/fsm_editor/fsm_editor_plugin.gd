@tool
extends EditorPlugin
## Registers the FSM graph authoring suite inside the Godot editor.
##
## Two pieces work together:
##   - an EditorInspectorPlugin that injects an "Edit FSM" button whenever a
##     FiniteStateMachine is being inspected (directly, or via a typed
##     export like CardData.fsm);
##   - a bottom-panel graph view (the existing fsm_editor scene) that the button
##     opens, bound to the exact FSM being inspected.

const FSM_EDITOR_SCENE := preload("res://src/editor/fsm/fsm_editor.tscn")
const FsmInspectorPlugin := preload("res://addons/fsm_editor/fsm_inspector_plugin.gd")
const BOTTOM_PANEL_TITLE := "FSM"

var _editor_view: Control
var _inspector_plugin: EditorInspectorPlugin


func _enter_tree() -> void:
	_editor_view = FSM_EDITOR_SCENE.instantiate()
	add_control_to_bottom_panel(_editor_view, BOTTOM_PANEL_TITLE)

	_inspector_plugin = FsmInspectorPlugin.new()
	_inspector_plugin.edit_graph_requested.connect(_on_edit_graph_requested)
	add_inspector_plugin(_inspector_plugin)


func _exit_tree() -> void:
	if _inspector_plugin != null:
		remove_inspector_plugin(_inspector_plugin)
		_inspector_plugin = null
	if _editor_view != null:
		remove_control_from_bottom_panel(_editor_view)
		_editor_view.queue_free()
		_editor_view = null


## Bind the bottom-panel view to the inspected FSM and reveal the panel.
func _on_edit_graph_requested(fsm: FiniteStateMachine, host: Object) -> void:
	_editor_view.open_fsm(fsm, host)
	make_bottom_panel_item_visible(_editor_view)
