extends Control

class_name Main

@export_file() var cardBuilderScene : String
@export var projectPicker : ResourcePicker
@export var basePackPicker : ResourcePicker

var execPath : String

static var dirs : SaveDirs

static var globalClassList : Array[Dictionary]

const TRANSLATIONS : PackedStringArray = [
	"Localisations/LOC - Cards.english.translation",
	"Localisations/LOC - Cards.greek.translation",
	"Localisations/LOC - FlightManual.english.translation",
	"Localisations/LOC - Stat.english.translation",
	"Localisations/LOC - Tutorial.english.translation",
]
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	execPath = OS.get_executable_path()
	execPath = execPath.replace(execPath.get_file(), "")
	
	if not FileAccess.file_exists(execPath + "SavedDir.tres"):
		ResourceSaver.save(SaveDirs.new(), execPath + "SavedDir.tres")
	
	dirs = ResourceLoader.load(execPath + "SavedDir.tres")
	
	projectPicker.SetFile(dirs.ModDir)
	basePackPicker.SetFile(dirs.BaseDataDir)
	
	ProjectSettings.set_setting("application/config/mod_dir", dirs.ModDir)

func _on_launch_pressed() -> void:
	if (dirs.ModDir.is_empty()):
		print("No dir selected")
		return
	
	if (dirs.BaseDataDir.is_empty()):
		print("No Mod Pack dir selected")
		return
	
	var editor_domain := TranslationServer.get_or_add_domain(&"")
	for locale: String in TRANSLATIONS:
		editor_domain.add_translation(load(dirs.ModDir + "/" +locale))
	editor_domain.set_locale_override("english")
	
	get_child(0).queue_free()
	
	globalClassList = ProjectSettings.get_global_class_list()
	ProjectSettings.load_resource_pack(dirs.BaseDataDir)
	globalClassList.append_array(ProjectSettings.get_global_class_list())
	
	if (FileAccess.file_exists(dirs.ModPackDir)):
		ProjectSettings.load_resource_pack(dirs.ModPackDir)
		globalClassList.append_array(ProjectSettings.get_global_class_list())
	
	LoadModScripts()
	
	var cBuilder = load(cardBuilderScene)
	var cardB : CardBuilder = cBuilder.instantiate()
	cardB.startingDir = dirs.ModDir
	add_child(cardB)

#----------------------------------------------------------------------
func _on_base_pack_picker_changed(t: String) -> void:
	dirs.BaseDataDir = t
	ResourceSaver.save(dirs, execPath + "SavedDir.tres")

#----------------------------------------------------------------------
func _on_project_picker_changed(t: String) -> void:
	dirs.ModDir = t
	ResourceSaver.save(dirs, execPath + "SavedDir.tres")
	print("Captain Directory changed to {0}".format([t]))
	ProjectSettings.set_setting("application/config/mod_dir", dirs.ModDir)

#----------------------------------------------------------------------
static func LoadModScripts() -> void:
	var modCardModuleDir = Main.dirs.ModDir + "/MetalEngineBase/Cardfight/Card/"
	
	var existingClasses: Dictionary[String, String]
	
	var global_class_list: Array[Dictionary] = Main.globalClassList
	
	# class name -> class info
	var classes: Dictionary[String, Dictionary] = {}

	for info: Dictionary in global_class_list:
		classes[info["class"]] = info

	for info: Dictionary in global_class_list:
		var clName: String = info["class"]

		#if CardHelper._inherits_from(clName, "CardModule", classes) or CardHelper._inherits_from(clName, "Card_Passive", classes):
		var class_path: String = info["path"]
		existingClasses[clName] = class_path
	
	var DirsToExplore :Array[String] = [modCardModuleDir]
	for g in DirsToExplore:
		var dir = DirAccess.open(g)
		if dir:
			dir.list_dir_begin()
			var file_name = dir.get_next()
			while file_name != "":
				if dir.current_is_dir():
					#print("Found directory: " + file_name)
					DirsToExplore.append(g + "/" + file_name)
				else:
					#print("Found file: " + file_name)
					if (file_name.ends_with(".gd")):
						#Gather data for class
						var clName = CardHelper.get_class_name_from_file(g + "/" + file_name)
						var baseClass = CardHelper.get_extended_class_from_file(g + "/" + file_name)

						if (existingClasses.has(clName)):
							var originalScriptPath = existingClasses[clName]
							var err = CardHelper.replace_class_source(originalScriptPath, g + "/" + file_name)
							if (err != OK):
								push_error("Replacing script returned with error {0}".format([err]))
						else:
							var customDic : Dictionary[String, String] = {
								"base" : baseClass,
								"class" : clName,
								"path" : g + "/" + file_name
								}
							
							Main.globalClassList.append(customDic)
								
				file_name = dir.get_next()
