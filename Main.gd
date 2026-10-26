extends Control

class_name Main

@export_file() var paletteCreatorScene : String
@export var projectPicker : ResourcePicker
@export var basePackPicker : ResourcePicker

var execPath : String

static var dirs : SaveDirs

#--------------------------------------------------------
func _ready() -> void:
	execPath = OS.get_executable_path()
	execPath = execPath.replace(execPath.get_file(), "")
	
	if not FileAccess.file_exists(execPath + "SavedDir.tres"):
		ResourceSaver.save(SaveDirs.new(), execPath + "SavedDir.tres")
	
	dirs = ResourceLoader.load(execPath + "SavedDir.tres")
	
	projectPicker.SetFile(dirs.ModDir)
	basePackPicker.SetFile(dirs.BaseDataDir)

#--------------------------------------------------------
func _on_launch_pressed() -> void:
	if (dirs.ModDir.is_empty()):
		print("No dir selected")
		return
	
	if (dirs.BaseDataDir.is_empty()):
		print("No Mod Pack dir selected")
		return
	
	get_child(0).queue_free()

	ProjectSettings.load_resource_pack(dirs.BaseDataDir)
	
	var pletteCreator : PackedScene = load(paletteCreatorScene)
	add_child(pletteCreator.instantiate())

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
