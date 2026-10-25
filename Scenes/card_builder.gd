extends PanelContainer

class_name CardBuilder

@export var Menu : PopupMenu
@export var cardShowcasee : Card
@export var cardDesc : CardDescriptor
@export var sect : PackedScene

var cards : Array[CardStats]
var currentCard : int = 0

var startingDir : String
var generalSection : CardModuleSection

func _ready() -> void:
	UpdateDilogues()

func SetCard(c : CardStats) -> void:
	cardShowcasee.SetCardStats(c)
	cardShowcasee.SetRealistic()
	
	var path : String = c.txFile
	if (path.contains("uid")):
		path = ResourceUID.ensure_path(c.txFile)

#--------------------------------------------------------
##Checks happening directory and pulls all of them out
func UpdateDilogues() -> void:
	Menu.clear()
	cards.clear()
	var DirsToExplore :Array[String] = [startingDir + "/Resources/Cards/"]
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
						var crd = ResourceLoader.load(g + "/" + file_name)
						if (crd is CardStats):
							cards.append(crd)
							Menu.add_item(crd.GetCardName())
				
				file_name = dir.get_next()
	SetCard(cards[currentCard])
	cardDesc.ConfigureCard(cards[currentCard])


func _on_popup_menu_index_pressed(index: int) -> void:
	currentCard = index
	SetCard(cards[index])
	cardDesc.ConfigureCard(cards[index])

func _on_panel_container_3_card_updated() -> void:
	SetCard(cards[currentCard])

##Make sure to save and add back the UID, since the file is saved outside the project it will never get a UID
func ResaveCard() -> void:
	var card = cards[currentCard]
	var originalUID = CardHelper.get_uid_from_tres(card.resource_path)
	
	ResourceSaver.save(card, card.resource_path)
	CardHelper.write_uid_to_tres(card.resource_path, originalUID)
	
	print("Card Saved At {0}".format([cards[currentCard].resource_path]))


func _on_new_pressed() -> void:
	var diag = FileDialog.new()
	diag.use_native_dialog = true
	diag.access = FileDialog.ACCESS_FILESYSTEM
	diag.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	diag.filters.append("*.tres")
	diag.current_dir = startingDir + "/Resources/Cards/"
	add_child(diag)
	diag.popup_centered()

	var f : String = await diag.file_selected
	if (f.is_empty()):
		return
	if (f.get_extension().is_empty()):
		f += ".tres"
	else :if (f.get_extension() != "tres"):
		return

	var newCard = CardStats.new()
	var cardName = f.get_file().replace(".tres", "")
	newCard.CardName = cardName
	
	if (FileAccess.file_exists(f)):
		var existingIndex = cards.find(ResourceLoader.load(f))
		cards[existingIndex] = newCard
		currentCard = existingIndex
		SetCard(newCard)
	else:
		cards.append(newCard)
		currentCard = cards.size() - 1
		SetCard(newCard)
	
	ResourceSaver.save(newCard, f)
	
