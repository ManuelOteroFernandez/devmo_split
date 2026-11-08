@tool
extends EditorPlugin

const DOCK_SCRIPT = preload("res://addons/devmo_split/splitter_dock.gd")

var _dock: VBoxContainer


func _enter_tree() -> void:
	_dock = DOCK_SCRIPT.new()
	add_control_to_dock(DOCK_SLOT_RIGHT_UL, _dock)


func _exit_tree() -> void:
	remove_control_from_docks(_dock)
	_dock.queue_free()
