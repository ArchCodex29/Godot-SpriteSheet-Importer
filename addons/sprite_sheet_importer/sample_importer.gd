@tool
extends EditorImportPlugin

func _get_importer_name():
	return "Kenney spritesheet importer"

func _get_visible_name():
	return "Kenney spritesheet importer"

func _get_recognized_extensions():
	return ["png"]

func _get_save_extension():
	return "tres"

func _get_resource_type():
	return "Texture" # Texture2D

func _get_preset_count():
	return 1

func _get_preset_name(preset_index):
	return "Default"

func _get_import_options(path: String, preset_index: int) -> Array:
	return [
		{
			"name": "xml file",
			"default_value": "",
			"property_hint": PROPERTY_HINT_FILE,
			"hint_string": "*.xml"
		}
	]

func _import(source_file, save_path, options, platform_variants, gen_files):
	var file = FileAccess.open(source_file, FileAccess.READ)
	if file == null:
		return FAILED
	var mesh = ArrayMesh.new()
	# Fill the Mesh with data read in "file", left as an exercise to the reader.

	var filename = save_path + "." + _get_save_extension()
	return ResourceSaver.save(mesh, filename)
