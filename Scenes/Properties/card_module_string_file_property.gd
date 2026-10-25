extends CardModuleProperty

class_name CardModuleStringFileProperty

@export var picker : ResourcePicker

func SetProperty(pName : String, value : Variant) -> void:
	super(pName, value)
	picker.SetFile(value)

func _on_resource_picker_changed(t: String) -> void:
	propertyValue = t
	PropertyChanged.emit(propertyName, t)
