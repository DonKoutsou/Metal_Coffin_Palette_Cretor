extends PanelContainer

class_name PaletterCreator

@export var Menu : PopupMenu
@export var ship : TextureRect
@export var colorParent : Control
@export var colorProp : PackedScene
@export var row : SpinBox
var startingDir : String

var currentShip : int
var currentRow : int = 1
var data : Array[HullData]

func _ready() -> void:
	UpdateDilogues()

func SetShip(d : HullData) -> void:
	for g in colorParent.get_children():
		g.queue_free()
	
	ship.texture = ResourceLoader.load(d.hullTexture)
	
	var palette : Texture2D
	if (d.hull_Pallete.is_empty()):
		palette = CreateNewPalette(d)
	else:
		palette = ImageTexture.create_from_image(Image.load_from_file(d.resource_path.replace("_Data.tres", "_Palette.png")))
	
	var shader : ShaderMaterial = ship.material
	shader.set_shader_parameter("palette_texture", palette)
	shader.set_shader_parameter("palette_index", currentRow)
	
	row.max_value = palette.get_height() - 2
	
	var colors = GetColorsFromPalette(palette)
	for colorIndex in colors.size():
		var c = colors[colorIndex]
		var cPop : CardModuleColorProperty = colorProp.instantiate()
		cPop.SetProperty("{0}#".format([colorIndex]), c)
		colorParent.add_child(cPop)
		cPop.PropertyChanged.connect(ColorChanged.bind(colorIndex))

func CreateNewPalette(d : HullData) -> ImageTexture:
	var im = ship.texture.get_image().duplicate()
	im.clear_mipmaps()
	var newPalleteColors = PaletteAnalyzer.create_Pallete(im)
	var newPallete : Image = Image.create(newPalleteColors.size(), 1, false, Image.FORMAT_RGB8)
	
	for pixelIndex in newPalleteColors.size():
		newPallete.set_pixel(pixelIndex, 0, newPalleteColors[pixelIndex])
	
	var hullLoc : String = d.resource_path.replace("res:/", Main.dirs.ModDir)
	var fileName = hullLoc.get_basename().replace("_Data","_Palette") + ".png"
	newPallete.save_png(fileName)
	d.hull_Pallete = fileName
	ResaveData(d)
	return ImageTexture.create_from_image(newPallete)

func UpdateShip() -> void:
	
	var palettePath = data[currentShip].resource_path.replace("_Data.tres", "_Palette.png")

	var im = Image.load_from_file(palettePath)
	var palette = ImageTexture.create_from_image(im)
	
	var shader : ShaderMaterial = ship.material
	shader.set_shader_parameter("palette_texture", palette)
	shader.set_shader_parameter("palette_index", currentRow)

func ColorChanged(_propName : String, c : Color, index : int) -> void:
	var palettePath = data[currentShip].resource_path.replace("_Data.tres", "_Palette.png")

	var im = Image.load_from_file(palettePath)

	im.set_pixel(index, currentRow, c)

	im.save_png(palettePath)
	ResaveData()
	UpdateShip()

func GetColorsFromPalette(palette : Texture2D, r : int = currentRow) -> Array[Color]:
	var maxRow = palette.get_height()
	if (r >= maxRow):
		r = 0
	var colors : Array[Color] = []
	var im = palette.get_image()
	
	for pixel in im.get_width():
		var pixelC = im.get_pixel(pixel, r)
		colors.append(pixelC)
	
	return colors
	
func SetRow(r : int) -> void:
	currentRow = r
#--------------------------------------------------------
##Checks happening directory and pulls all of them out
func UpdateDilogues() -> void:
	Menu.clear()
	data.clear()
	var DirsToExplore :Array[String] = [Main.dirs.ModDir + "/Assets/ShipTextures"]
	for g in DirsToExplore:
		var dir = DirAccess.open(g)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					print("Found directory: " + file_name)
					DirsToExplore.append(g + "/" + file_name)
				else:
					print("Found file: " + file_name)
					if (file_name.ends_with(".tres")):
						var dt = ResourceLoader.load(g + "/" + file_name)
						if (dt is HullData):
							data.append(dt)
							Menu.add_item(file_name)
				
				file_name = dir.get_next()
				
	SetShip(data[currentShip])


func _on_popup_menu_index_pressed(index: int) -> void:
	currentShip = index
	SetShip(data[currentShip])

##Make sure to save and add back the UID, since the file is saved outside the project it will never get a UID
func ResaveData(d : HullData = null) -> void:
	if (!d):
		d = data[currentShip]
	var originalUID = CardHelper.get_uid_from_tres(d.resource_path)
	
	ResourceSaver.save(d, d.resource_path)
	CardHelper.write_uid_to_tres(d.resource_path, originalUID)
	
	print("Data Saved At {0}".format([data[currentShip].resource_path]))


func _on_palette_row_value_changed(value: float) -> void:
	currentRow = roundi(value + 1)
	SetShip(data[currentShip])


func _on_reset_pressed() -> void:
	var palette = ResourceLoader.load(data[currentShip].hull_Pallete)
	var actualPath = palette.resource_path.replace("res:/", Main.dirs.ModDir)
	
	var originalColors = GetColorsFromPalette(palette)
	
	palette = ImageTexture.create_from_image(Image.load_from_file(actualPath))
	var im : Image = palette.get_image()
	for g in originalColors.size():
		var col = originalColors[g]
		im.set_pixel(g, currentRow, col)
	im.save_png(actualPath)
	SetShip(data[currentShip])


func _on_add_pressed() -> void:
	var palette = ResourceLoader.load(data[currentShip].hull_Pallete)
	var actualPath = palette.resource_path.replace("res:/", Main.dirs.ModDir)
	palette = ImageTexture.create_from_image(Image.load_from_file(actualPath))
	
	var originalColors = GetColorsFromPalette(palette, 0)
	
	var newRowNumber = palette.get_height()
	
	var im : Image = palette.get_image().duplicate(true)
	im.resize(palette.get_width(), newRowNumber + 1)
	
	#put back olddata
	for rowIndex in newRowNumber:
		var rowCols = GetColorsFromPalette(palette, rowIndex)
		for colorIndex in rowCols.size():
			var col = rowCols[colorIndex]
			im.set_pixel(colorIndex, rowIndex, col)
	
	#fill new line
	for g in originalColors.size():
		var col = originalColors[g]
		im.set_pixel(g, newRowNumber, col)
		
	im.save_png(actualPath)
	SetShip(data[currentShip])


func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("ZoomIn")):
		var newScale = clamp(ship.offset_transform_scale.x + 0.1 , 0.1, 6)
		ship.offset_transform_scale = Vector2(newScale,newScale)
	if (event.is_action_pressed("ZoomOut")):
		var newScale = clamp(ship.offset_transform_scale.x - 0.1 , 0.1, 6)
		ship.offset_transform_scale = Vector2(newScale,newScale)
