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
var currentPallete : Image
var data : Array[HullData]

var unsavedChanged : bool = false
#--------------------------------------------------------
func _ready() -> void:
	UpdateData()

#--------------------------------------------------------
func SetShip(d : HullData) -> void:
	ship.texture = ResourceLoader.load(d.hullTexture)
	
	var palette : Texture2D
	if (d.hull_Pallete.is_empty()):
		palette = CreateNewPalette(d)
	else:
		currentPallete = Image.load_from_file(d.resource_path.replace("_Data.tres", "_Palette.png"))
		palette = ImageTexture.create_from_image(currentPallete)
	
	var shader : ShaderMaterial = ship.material
	shader.set_shader_parameter("palette_texture", palette)
	shader.set_shader_parameter("palette_index", currentRow)
	
	row.max_value = palette.get_height() - 2
	
	RefreshPaletteUI()

func RefreshPaletteUI() -> void:
	for g in colorParent.get_children():
		g.queue_free()
	var palette = ImageTexture.create_from_image(currentPallete)
	var colors = GetColorsFromPalette(palette)
	for colorIndex in colors.size():
		var c = colors[colorIndex]
		var cPop : CardModuleColorProperty = colorProp.instantiate()
		cPop.SetProperty("{0}#".format([colorIndex]), c)
		colorParent.add_child(cPop)
		cPop.PropertyChanged.connect(ColorChanged.bind(colorIndex))

#--------------------------------------------------------
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
	currentPallete = newPallete
	d.hull_Pallete = fileName
	return ImageTexture.create_from_image(newPallete)

#--------------------------------------------------------
func UpdateShip() -> void:
	var palette = ImageTexture.create_from_image(currentPallete)
	
	var shader : ShaderMaterial = ship.material
	shader.set_shader_parameter("palette_texture", palette)
	shader.set_shader_parameter("palette_index", currentRow)
	

#--------------------------------------------------------
func ColorChanged(_propName : String, c : Color, index : int) -> void:
	currentPallete.set_pixel(index, currentRow, c)
	UpdateShip()
	unsavedChanged = true

#--------------------------------------------------------
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
	
#--------------------------------------------------------
func UpdateData() -> void:
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

#--------------------------------------------------------
func _on_popup_menu_index_pressed(index: int) -> void:
	if (unsavedChanged):
		var confirm = ConfirmationDialog.new()
		get_tree().root.add_child(confirm)
		confirm.dialog_text = "Palette has unsaved changes.\nContinue?"
		confirm.popup_centered()
		confirm.confirmed.connect(ChangeShip.bind(index))
	else:
		ChangeShip(index)

func ChangeShip(index : int) -> void:
	unsavedChanged = false
	currentShip = index
	SetShip(data[currentShip])

#--------------------------------------------------------
func _on_palette_row_value_changed(value: float) -> void:
	currentRow = roundi(value + 1)
	UpdateShip()
	RefreshPaletteUI()
	unsavedChanged = true

#--------------------------------------------------------
func _on_reset_pressed() -> void:
	var palette = ResourceLoader.load(data[currentShip].hull_Pallete)

	var originalColors = GetColorsFromPalette(palette, 0)
	
	for g in originalColors.size():
		var col = originalColors[g]
		currentPallete.set_pixel(g, currentRow, col)
	
	UpdateShip()
	RefreshPaletteUI()
	unsavedChanged = true

#--------------------------------------------------------
func _on_add_pressed() -> void:
	var palette = ImageTexture.create_from_image(currentPallete)
	
	var originalColors = GetColorsFromPalette(palette, 0)
	
	var newRowNumber = palette.get_height()

	currentPallete.resize(palette.get_width(), newRowNumber + 1)
	
	#put back olddata
	for rowIndex in newRowNumber:
		var rowCols = GetColorsFromPalette(palette, rowIndex)
		for colorIndex in rowCols.size():
			var col = rowCols[colorIndex]
			currentPallete.set_pixel(colorIndex, rowIndex, col)
	
	#fill new line
	for g in originalColors.size():
		var col = originalColors[g]
		currentPallete.set_pixel(g, newRowNumber, col)

	UpdateShip()
	row.max_value = currentPallete.get_height() - 2
	unsavedChanged = true

#--------------------------------------------------------
func _on_texture_rect_gui_input(event: InputEvent) -> void:
	if (event.is_action_pressed("ZoomIn")):
		var newScale = clamp(ship.offset_transform_scale.x + 0.1 , 0.1, 6)
		ship.offset_transform_scale = Vector2(newScale,newScale)
	if (event.is_action_pressed("ZoomOut")):
		var newScale = clamp(ship.offset_transform_scale.x - 0.1 , 0.1, 6)
		ship.offset_transform_scale = Vector2(newScale,newScale)

#--------------------------------------------------------
func _on_save_pressed() -> void:
	var palettePath = data[currentShip].resource_path.replace("_Data.tres", "_Palette.png")
	currentPallete.save_png(palettePath)
	unsavedChanged = false
	print("Palette Saved At {0}".format([palettePath]))
