extends CardModuleProperty

class_name  CardModuleColorProperty

@export var colorPicker : ColorPickerButton

func SetProperty(pName : String, value : Variant) -> void:
	super(pName, value)
	colorPicker.color = value
	
func _on_color_picker_button_color_changed(color: Color) -> void:
	propertyValue = color
	PropertyChanged.emit(propertyName, color)
