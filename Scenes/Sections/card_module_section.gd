extends FoldableCont

class_name CardModuleSection

@export var moduleDescriptorScene : PackedScene
@export var passiveModuleDescriptorScene : PackedScene

@export var boolScene : PackedScene
@export var intScene : PackedScene
@export var enumScene : PackedScene
@export var floatScene : PackedScene
@export var stringScene : PackedScene
@export var stringFileScene : PackedScene
@export var arrayScene : PackedScene

signal Added(new)
signal Removed(removed)
signal MovedUp(moved)
signal MovedDown(moved)
signal PropertyChanged()

var SectionName : String = ""
var SectionT : SectionType
var modAmm : int = 0
var MaxAmm : int = 0

enum SectionType {
	MODULE,
	PASSIVE,
	DAMAGE_INFO,
	BOOL,
	FLOAT,
	INT,
	STRING,
}

func SetSectionName(sectionName : String) -> void:
	SectionName = sectionName
	title = sectionName

func UpdateSectionTitle() -> void:
	title = SectionName
	if (modAmm > 0):
		title += " ({0})".format([modAmm])

#-------------------------------------------------------------------
##Creates a container for the passive and adds it to section
func ConfigurePassive(passive : Card_Passive) -> void:
	modAmm += 1
	UpdateSectionTitle()
	
	var moduleContainer : CardPassiveModuleDescriptor = passiveModuleDescriptorScene.instantiate()
	GetContainer().add_child(moduleContainer)
	moduleContainer.ConfigurePassive(passive)
	moduleContainer.title = CardHelper.prettify_class_name(passive.get_script().get_global_name())
	moduleContainer.folded = true
	
	moduleContainer.Remove.connect(PassiveRemoved.bind(passive))
	
	moduleContainer.PassivePropertyChanged.connect(OnPropertyChanged.bind(passive))
	moduleContainer.DissableMoving()
	var props : Array[Dictionary] = CardHelper.get_all_script_variables(passive.Module)
	
	for prop : Dictionary in props :
		var moduleDesc = HandleProperty(prop, passive.Module)
		if (moduleDesc):
			moduleContainer.GetModulePropertyParent().add_child(moduleDesc)

#-------------------------------------------------------------------
##Creates a container for the module and adds it to section
func ConfigureModule(module : CardModule) -> void:
	if (module == null):
		return
	
	modAmm += 1
	UpdateSectionTitle()
	
	var moduleContainer : CardModuleDescriptor = moduleDescriptorScene.instantiate()
	GetContainer().add_child(moduleContainer)
	moduleContainer.title = CardHelper.prettify_class_name(module.get_script().get_global_name())
	moduleContainer.folded = true
	
	if (MaxAmm > 1):
		moduleContainer.MoveUp.connect(ModuleMovedUp.bind(module, moduleContainer))
		moduleContainer.MoveDown.connect(ModuleMovedDown.bind(module, moduleContainer))
	else:
		moduleContainer.DissableMoving()
	
	
		
	moduleContainer.Remove.connect(ModuleRemoved.bind(module))
	
	var props : Array[Dictionary] = CardHelper.get_all_script_variables(module)
	
	for prop : Dictionary in props :
		var moduleDesc = HandleProperty(prop, module)
		if (moduleDesc):
			moduleContainer.GetModulePropertyParent().add_child(moduleDesc)

#-------------------------------------------------------------------
##Creates a container for the damage info and adds it to section
func ConfigureDamageInfo(info : DamageInfo) -> void:
	if (info == null):
		return
	
	modAmm += 1
	UpdateSectionTitle()
	
	var moduleContainer : CardModuleDescriptor = moduleDescriptorScene.instantiate()
	GetContainer().add_child(moduleContainer)
	moduleContainer.title = CardHelper.prettify_class_name(info.get_script().get_global_name())
	moduleContainer.folded = true
	
	if (MaxAmm > 1):
		moduleContainer.MoveUp.connect(DamageInfoMovedUp.bind(info, moduleContainer))
		moduleContainer.MoveDown.connect(DamageInfoMovedDown.bind(info, moduleContainer))
	else:
		moduleContainer.DissableMoving()
	
	moduleContainer.Remove.connect(DamageInfoRemoved.bind(info))
	
	var props : Array[Dictionary] = CardHelper.get_all_script_variables(info)
	
	for prop : Dictionary in props :
		var moduleDesc = HandleProperty(prop, info)
		if (moduleDesc):
			moduleContainer.GetModulePropertyParent().add_child(moduleDesc)

func ConfigureArrayProp(desc : CardModuleProperty) -> void:
	GetContainer().add_child(desc)

func ManualProp(prop : Dictionary, obj : Object) -> void:
	var moduleDesc = HandleProperty(prop, obj)
	if (moduleDesc):
		GetContainer().add_child(moduleDesc)
	
#-------------------------------------------------------------------
##Creates a container for the property and returns it
func HandleProperty(prop : Dictionary, obj : Object) -> Control:
	var properyName : String = prop["name"]
	var type : Variant.Type = prop["type"]
	var hint : PropertyHint = prop["hint"]
	var hintString : String = prop["hint_string"]
	var usage : PropertyUsageFlags = prop["usage"]
		
	var moduleDesc : CardModuleProperty
	match (type):
		Variant.Type.TYPE_BOOL:
			moduleDesc = boolScene.instantiate()
		Variant.Type.TYPE_INT:
			if (hint == PropertyHint.PROPERTY_HINT_ENUM):
				var enumData = CardHelper.get_exported_enum_data(prop)
				var enumDesc : CardModuleEnumProperty = enumScene.instantiate()
				enumDesc.SetOptions(enumData)
				moduleDesc = enumDesc
			else:
				moduleDesc = intScene.instantiate()
				if hint == PropertyHint.PROPERTY_HINT_RANGE:
					var range_data: PackedStringArray = hintString.split(",")
					moduleDesc.SetMax(str_to_var(range_data[1]))
					
		Variant.Type.TYPE_FLOAT:
			moduleDesc = floatScene.instantiate()
			if hint == PropertyHint.PROPERTY_HINT_RANGE:
				var range_data: PackedStringArray = hintString.split(",")
				moduleDesc.SetMax(str_to_var(range_data[1]))
		
		Variant.Type.TYPE_STRING:
			if (hint == PropertyHint.PROPERTY_HINT_FILE):
				var fileDesc : CardModuleStringFileProperty = stringFileScene.instantiate()
				fileDesc.picker.resource_Type = FileDialog.FileMode.FILE_MODE_OPEN_FILE
				fileDesc.picker.allowExternalLinks = false
				var filters = hintString.split(",")
				fileDesc.picker.resource_Tyoes = filters
				moduleDesc = fileDesc
			else:
				moduleDesc = stringScene.instantiate()
		
		Variant.Type.TYPE_ARRAY:
			var infoArr : Array = obj.get(properyName)
			
			
			
			var arrInfo = get_array_type_info(infoArr)
			
			if (arrInfo["script"]):
				var newSect : CardModuleSection = load(scene_file_path).instantiate()
				newSect.SetSectionName(properyName)
				
				newSect.Added.connect(AddedInArray.bind(infoArr))
				newSect.Removed.connect(RemovedFromArray.bind(infoArr))
				
				newSect.MovedUp.connect(MovedUpInArray.bind(infoArr))
				newSect.MovedDown.connect(MovedDownInArray.bind(infoArr))
				
				newSect.PropertyChanged.connect(ModulePropertyChanged)
				newSect.MaxAmm = 10
			
				var script : Script = arrInfo["script"]
				var instance = script.new()
				if (instance is DamageInfo):
					newSect.SectionT = SectionType.DAMAGE_INFO
					
					for index in infoArr.size():
						var v = infoArr[index]
						newSect.ConfigureDamageInfo(v)
				
				if (instance is CardModule):
					newSect.SectionT = SectionType.MODULE
					
					for index in infoArr.size():
						var v = infoArr[index]
						newSect.ConfigureModule(v)
				
				return newSect
			else:
				var arrType = arrInfo["builtin_type"]
				
				var arrDesc : CardModuleArrayProperty = arrayScene.instantiate()
				arrDesc.arrType = arrType
				arrDesc.arr = infoArr
				
				match (arrType):
						Variant.Type.TYPE_BOOL:
							arrDesc.scene = boolScene
						Variant.Type.TYPE_INT:
							if (hintString.length() > 3):
								arrDesc.scene = enumScene
								arrDesc.enumData = CardHelper.get_exported_enum_data_from_hint(hintString.substr(4, hintString.length()))
							else:
								arrDesc.scene = intScene
						Variant.Type.TYPE_FLOAT:
							arrDesc.scene = floatScene
						Variant.Type.TYPE_STRING:
							arrDesc.scene = stringScene
				
				moduleDesc = arrDesc
		_:
			printerr("Could not map property {0} of type {1}".format([properyName, type]))
			return

	moduleDesc.SetProperty(properyName, obj.get(properyName))
	moduleDesc.PropertyChanged.connect(OnPropertyChanged.bind(obj))
		
	return moduleDesc

func get_array_type_info(arr: Array) -> Dictionary:
	if not arr.is_typed():
		return {"typed": false}

	return {
		"typed": true,
		"builtin_type": arr.get_typed_builtin(),
		"builtin_type_name": type_string(arr.get_typed_builtin()),
		"class_name": arr.get_typed_class_name(),
		"script": arr.get_typed_script()
	}
#-------------------------------------------------------------------
func AddedInArray(added , arr : Array) -> void:
	arr.append(added)
	PropertyChanged.emit()

#-------------------------------------------------------------------
func RemovedFromArray(removed, arr : Array) -> void:
	arr.erase(removed)
	PropertyChanged.emit()

#-------------------------------------------------------------------
func MovedUpInArray(moved, arr : Array) -> void:
	var index = arr.find(moved)
	if (index > 0):
		var saved = arr[index - 1]
		arr[index - 1] = moved
		arr[index] = saved
		PropertyChanged.emit()

#-------------------------------------------------------------------
func MovedDownInArray(moved, arr : Array) -> void:
	var index = arr.find(moved)
	if (index < arr.size() - 1):
		var saved = arr[index + 1]
		arr[index + 1] = moved
		arr[index] = saved
		PropertyChanged.emit()

#-------------------------------------------------------------------
func ModulePropertyChanged() -> void:
	PropertyChanged.emit()

#-------------------------------------------------------------------
func AddModule() -> CardModule:
	if (modAmm == MaxAmm):
		print("Cant add more modules in this section")
		return
		
	var newModule = await SelectModule()
	
	ConfigureModule(newModule)
	return newModule

#-------------------------------------------------------------------
func AddPassive() -> Card_Passive:
	if (modAmm == MaxAmm):
		print("Cant add more modules in this section")
		return
		
	var newP = await SelectPassive()
	
	var newModule = await SelectModule(false)
	newP.Module = newModule
	
	ConfigurePassive(newP)
	return newP

#-------------------------------------------------------------------
func AddDamageInfo() -> DamageInfo:
	if (modAmm == MaxAmm):
		print("Cant add more modules in this section")
		return
	
	var newInfo = DamageInfo.new()
	ConfigureDamageInfo(newInfo)
	
	return newInfo

#-------------------------------------------------------------------
func SelectPassive() -> Card_Passive:
	var passiveList = CardHelper.GetPassiveList()
	
	var opt : OptionButton = OptionButton.new()
	for g in passiveList:
		opt.add_item(g)
	
	add_child(opt)
	opt.show_popup()
	var selected = await opt.item_selected
	opt.queue_free()
	
	var selectedName = passiveList.keys()[selected]
	
	return passiveList[selectedName].new()

#-------------------------------------------------------------------
func SelectModule(allowPassive : bool = true) -> CardModule:
	var moduleList = CardHelper.GetModuleList(allowPassive)
	
	var opt : OptionButton = OptionButton.new()
	opt.allow_reselect = true
	opt.search_bar_enabled = true
	for g in moduleList:
		opt.add_item(g)
	
	add_child(opt)
	opt.show_popup()
	var selected = await opt.item_selected
	opt.queue_free()
	
	var selectedName = moduleList.keys()[selected]
	
	var script : GDScript = moduleList[selectedName]
	var moduleInstance = moduleList[selectedName].new()
	var uid = ResourceUID.path_to_uid(script.resource_path)
	moduleInstance.set_meta("_custom_type_script", uid)
	return moduleInstance

#-------------------------------------------------------------------
func ModuleMovedUp(movedModule : CardModule, moduleDesc : CardModuleDescriptor) -> void:
	var content = GetContainer().get_children()
	var index = content.find(moduleDesc)
	if (index == 0):
		printerr("Cant move more up")
		return
		
	GetContainer().move_child(moduleDesc, index - 1)
	MovedUp.emit(movedModule)

#-------------------------------------------------------------------
func ModuleMovedDown(movedModule : CardModule, moduleDesc : CardModuleDescriptor) -> void:
	var content = GetContainer().get_children()
	var index = content.find(moduleDesc)
	if (index == content.size() - 1):
		printerr("Cant move more down")
		return
		
	GetContainer().move_child(moduleDesc, index + 1)
	
	MovedDown.emit(movedModule)

#-------------------------------------------------------------------
func DamageInfoMovedUp(movedInfo : DamageInfo, moduleDesc : CardModuleDescriptor) -> void:
	var content = GetContainer().get_children()
	var index = content.find(moduleDesc)
	if (index == 0):
		printerr("Cant move more up")
		return
		
	GetContainer().move_child(moduleDesc, index - 1)
	
	MovedUp.emit(movedInfo)

#-------------------------------------------------------------------
func  DamageInfoMovedDown(movedInfo : DamageInfo, moduleDesc : CardModuleDescriptor) -> void:
	var content = GetContainer().get_children()
	var index = content.find(moduleDesc)
	if (index == content.size() - 1):
		printerr("Cant move more down")
		return
		
	GetContainer().move_child(moduleDesc, index + 1)
	
	MovedDown.emit(movedInfo)

#-------------------------------------------------------------------
func ModuleRemoved(removedModule : CardModule) -> void:
	Removed.emit(removedModule)
	modAmm -= 1
	UpdateSectionTitle()

#-------------------------------------------------------------------
func DamageInfoRemoved(removedInfo : DamageInfo) -> void:
	Removed.emit(removedInfo)
	modAmm -= 1
	UpdateSectionTitle()

#-------------------------------------------------------------------
func PassiveRemoved(removedPassive : Card_Passive) -> void:
	Removed.emit(removedPassive)
	modAmm -= 1
	UpdateSectionTitle()

#-------------------------------------------------------------------
func OnPropertyChanged(pName : String, newValue : Variant, obj : Object) -> void:
	obj.set(pName, newValue)
	PropertyChanged.emit()

func ArrayPropertyChanged(index : int, newValue : Variant, arr : Array) -> void:
	arr[index] = newValue
	PropertyChanged.emit()

#-------------------------------------------------------------------
func _on_add_pressed() -> void:
	if (SectionT == SectionType.MODULE):
		var newMod = await AddModule()
		Added.emit(newMod)
	else: if (SectionT == SectionType.PASSIVE):
		var newPassive = await AddPassive()
		Added.emit(newPassive)
	else: if (SectionT == SectionType.DAMAGE_INFO):
		var newInfo = AddDamageInfo()
		Added.emit(newInfo)
	else: if (SectionT == SectionType.DAMAGE_INFO):
		var newInfo = AddDamageInfo()
		Added.emit(newInfo)
		
