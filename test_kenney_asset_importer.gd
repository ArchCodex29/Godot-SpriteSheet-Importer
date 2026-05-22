extends SceneTree
# @tool
# extends EditorScript

@export var xmlPath: String = "res://Assets/Isometric/vehicles/Spritesheet/sheet_allCars.xml":
	set(new_path):
		xmlPath = new_path

@export var pngPath: String = "res://Assets/Isometric/vehicles/Spritesheet/sheet_allCars.png":
	set(new_path):
		pngPath = new_path

# _repacked
@export var outputPath: String = "res://Assets/Isometric/vehicles/Spritesheet/sheet_allCars_repacked.png":
	set(new_path):
		outputPath = new_path


func _init():
# func _run():
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
	src.load(pngPath)

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

	# FIX 5: globalize res:// path so save_png works even in read-only project dirs
	var abs_output = ProjectSettings.globalize_path(outputPath)
	atlas.save_png(abs_output)

	# FIX 4: pass cell_w / cell_h so _generate_tileset can set texture_region_size
	_generate_tileset(atlas, regions, outputPath, cell_w, cell_h)

	print("Done")
	quit(0)

# FIX 4: added cell_w and cell_h parameters
func _generate_tileset(image: Image, regions: Array, output_path: String, cell_w: int, cell_h: int):

	var texture = ImageTexture.create_from_image(image)

	var tileset = TileSet.new()
	var source = TileSetAtlasSource.new()

	source.texture = texture

	# FIX 1: set texture_region_size so the atlas source knows each cell's pixel size.
	# This replaces the non-existent set_texture_region() per-tile calls — Godot 4
	# derives every tile's pixel rect automatically from (atlas_coords * texture_region_size).
	source.texture_region_size = Vector2i(cell_w, cell_h)

	tileset.add_source(source, 0)

	# FIX 3: use the actual repacked cell dimensions, not a guess based on tile_w / 2.
	# Adjust tile_size here if your isometric grid uses a different logical size.

	# TODO : input prop to ask tile shape and act accordingly
	# for now, assume isometric
	tileset.tile_size = Vector2i(cell_w, cell_h / 2)
	tileset.tile_shape = TileSet.TileShape.TILE_SHAPE_ISOMETRIC

	# --- create tiles ---
	for r in regions:
		var coords = r.coords

		source.create_tile(coords)

		# FIX 1 (cont): removed source.set_texture_region() — not needed, handled by
		# texture_region_size above.

		# FIX 2: texture_origin lives on TileData, not on the source itself.
		# get_tile_data(atlas_coords, alternative_tile_index) returns the TileData object.
		var tile_data: TileData = source.get_tile_data(coords, 0)

		# Compensate for the bottom-center padding baked in during atlas packing,
		# so the tile's anchor sits at the visual bottom-center of the sprite.
		# tile_data.texture_origin = Vector2i(
		# 	(r.size.x - cell_w) / 2,  # undo horizontal centering offset
		# 	r.size.y - cell_h          # undo vertical bottom-align offset
		# )

		tile_data.texture_origin = Vector2i(
			0,
			0
		)

	# --- save ---
	var tres_path = output_path.replace(".png", ".tres")
	ResourceSaver.save(tileset, tres_path)

	print("TileSet saved to:", tres_path)