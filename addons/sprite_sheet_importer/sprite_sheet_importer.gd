@tool
extends EditorPlugin

var inspector_plugin: EditorImportPlugin = null
const Importer = preload("res://addons/sprite_sheet_importer/sample_importer.gd")
func _enable_plugin() -> void:
	# Add autoloads here.
	#inspector_plugin = MyCustomImporter.new()
	inspector_plugin = Importer.new()
	add_import_plugin(inspector_plugin)


func _disable_plugin() -> void:
	# Remove autoloads here.
	#inspector_plugin = null
	remove_import_plugin(inspector_plugin)
	pass

func _enter_tree():
	#add_import_plugin(inspector_plugin, true)
	pass

func _exit_tree():
	#remove_import_plugin(inspector_plugin)
	pass
