@tool
extends EditorPlugin

const Importer = preload("res://addons/sprite_sheet_importer/xml_importer.gd")
var inspector_plugin: EditorImportPlugin = Importer.new()

func _enable_plugin() -> void:
	pass


func _disable_plugin() -> void:
	pass
	
func _enter_tree():
	add_import_plugin(inspector_plugin, true)
	pass

func _exit_tree():
	remove_import_plugin(inspector_plugin)
	pass
