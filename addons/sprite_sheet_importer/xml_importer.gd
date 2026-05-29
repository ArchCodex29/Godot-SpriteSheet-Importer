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
	var xml_path = options["xml file"]
	if xml_path == null or xml_path.is_empty():
		return FAILED
	_execute(source_file, xml_path, gen_files)

func _execute(pngPath:String, xmlPath:String, gen_files:Array[String]):

	var xml = XMLParser.new()
	xml.open(xmlPath)

	var sprites = []

	while xml.read() == OK:
		if xml.get_node_type() == XMLParser.NODE_ELEMENT and xml.get_node_name() == "SubTexture":
			sprites.append({
				"name": xml.get_named_attribute_value("name"),
				"x": int(xml.get_named_attribute_value("x")),
				"y": int(xml.get_named_attribute_value("y")),
				"w": int(xml.get_named_attribute_value("width")),
				"h": int(xml.get_named_attribute_value("height")),
			})

	var src = Image.new()
	var bytes = FileAccess.get_file_as_bytes(pngPath)
	src.load_png_from_buffer(bytes)

	var cell_w = 0
	var cell_h = 0

	for s in sprites:
		cell_w = max(cell_w, s.w)
		cell_h = max(cell_h, s.h)

	var cols = int(ceil(sqrt(sprites.size())))
	var rows = int(ceil(float(sprites.size()) / cols))

	var atlas = Image.create(cols * cell_w, rows * cell_h, false, Image.FORMAT_RGBA8)

	var regions = []

	for i in sprites.size():
		var s = sprites[i]

		var col = i % cols
		var row = i / cols #tried apply "float" to i var, but messed up the final image

		var cell_x = col * cell_w
		var cell_y = row * cell_h

		var src_rect = Rect2i(s.x, s.y, s.w, s.h)

		# Bottom-center align sprite within its cell
		var dst = Vector2i(
			cell_x + (cell_w - s.w) / 2,
			cell_y + (cell_h - s.h)
		)

		atlas.blit_rect(src, src_rect, dst)

		regions.append({
			"coords": Vector2i(col, row),
			"region": Rect2i(dst.x, dst.y, s.w, s.h),
			"size": Vector2i(s.w, s.h)
		})

	var output_path = pngPath.get_basename()
	var abs_output =  output_path + "_repacked.png"
	gen_files.append(abs_output)
	atlas.save_png(abs_output)
	_write_default_texture_import(abs_output)
	if Engine.is_editor_hint():
		var fs := EditorInterface.get_resource_filesystem()
		fs.update_file(abs_output)
	
	_generate_tileset(atlas, regions, output_path, cell_w, cell_h)

	print("Done")

func _generate_tileset(image: Image, regions: Array, output_path: String, cell_w: int, cell_h: int):
	var texture = ImageTexture.create_from_image(image)
	var tileset = TileSet.new()
	var source = TileSetAtlasSource.new()

	source.texture = texture
	source.texture_region_size = Vector2i(cell_w, cell_h)
	tileset.add_source(source, 0)

	# TODO : input prop to ask tile shape and act accordingly
	# for now, assume isometric
	tileset.tile_size = Vector2i(cell_w, cell_h / 2)
	tileset.tile_shape = TileSet.TileShape.TILE_SHAPE_ISOMETRIC

	for r in regions:
		var coords = r.coords
		source.create_tile(coords)
		var tile_data: TileData = source.get_tile_data(coords, 0)

		tile_data.texture_origin = Vector2i(
			0,
			0
		)

	var tres_path = output_path + ".tres"
	ResourceSaver.save(tileset, tres_path)
	#gen_files.append(tres_path)
	print("TileSet saved to:", tres_path)

func _write_default_texture_import(png_path: String) -> void:
	var import_path = png_path + ".import"
	# Don't clobber a user-customized import config if it already exists.
	if FileAccess.file_exists(import_path):
		return

	var content := "[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n"
	var f = FileAccess.open(import_path, FileAccess.WRITE)
	if f:
		f.store_string(content)
