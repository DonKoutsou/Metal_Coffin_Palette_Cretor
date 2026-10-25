extends CardModuleProperty

class_name CardModuleArrayProperty

@export var arrayContentParent : Control

var arr : Array
var arrType

var folded : bool  = true:
	set(value):
		folded = value
		FoldToggled(value)
		
var scene : PackedScene
var enumData : PackedStringArray

func SetProperty(pName : String, value : Variant) -> void:
	super(pName, value)
	$VBoxContainer2/HBoxContainer/Expand.text = pName
	arr = value
	for index : int in value.size():
		var v = value[index]
		
		var prop : CardModuleProperty = scene.instantiate()
		if (prop is CardModuleEnumProperty):
			prop.SetOptions(enumData)
		
		prop.SetProperty(var_to_str(index), v)
		
		arrayContentParent.add_child(prop)
		
		prop.PropertyChanged.connect(PropChanged)
		prop.RemoveRequest.connect(OnRemove)
		prop.SetRemovable(true)
		
		

func _on_add_pressed() -> void:
	match arrType:
		TYPE_INT:
			arr.append(0)
			var prop : CardModuleProperty = scene.instantiate()
			if (prop is CardModuleEnumProperty):
				prop.SetOptions(enumData)
				
			prop.SetProperty(var_to_str(arr.size() - 1), 0)
			
			arrayContentParent.add_child(prop)
			
			prop.PropertyChanged.connect(PropChanged)
			prop.RemoveRequest.connect(OnRemove)
			prop.SetRemovable(true)
			
		TYPE_FLOAT:
			arr.append(0.0)
			var prop : CardModuleProperty = scene.instantiate()
			prop.SetProperty(var_to_str(arr.size() - 1), 0.0)
			
			arrayContentParent.add_child(prop)
			
			prop.PropertyChanged.connect(PropChanged)
			prop.RemoveRequest.connect(OnRemove)
			prop.SetRemovable(true)
			
		TYPE_BOOL:
			arr.append(false)
			var prop : CardModuleProperty = scene.instantiate()
			prop.SetProperty(var_to_str(arr.size() - 1), false)
			
			arrayContentParent.add_child(prop)
			
			prop.PropertyChanged.connect(PropChanged)
			prop.RemoveRequest.connect(OnRemove)
			prop.SetRemovable(true)
			
		TYPE_STRING:
			arr.append("")
			var prop : CardModuleProperty = scene.instantiate()
			prop.SetProperty(var_to_str(arr.size() - 1), "")
			
			arrayContentParent.add_child(prop)
			
			prop.PropertyChanged.connect(PropChanged)
			prop.RemoveRequest.connect(OnRemove)
			prop.SetRemovable(true)
	
func OnRemove(value : Variant) -> void:
	var index = arr.find(value)
	arr.remove_at(index)
	arrayContentParent.get_child(index).queue_free()

func PropChanged(pName : String, newValue : Variant) -> void:
	arr[str_to_var(pName)] = newValue
	PropertyChanged.emit(propertyName , arr)


func _on_expand_pressed() -> void:
	folded = !folded

func FoldToggled(t : bool) -> void:
	if (t):
		$VBoxContainer2/HBoxContainer/Expand.icon = load("res://Scenes/FoldableContainer/Arrow.png")
	else:
		$VBoxContainer2/HBoxContainer/Expand.icon = load("res://Scenes/FoldableContainer/Arrow2.png")
	arrayContentParent.get_parent().visible = !t
