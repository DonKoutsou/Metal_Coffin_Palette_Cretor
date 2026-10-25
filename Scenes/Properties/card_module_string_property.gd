extends CardModuleProperty

class_name CardModuleStringProperty

@export var line : LineEdit

func SetProperty(pName : String, value : Variant) -> void:
	super(pName, value)
	line.text = value
	
func _on_line_edit_text_changed(new_text: String) -> void:
	propertyValue = new_text
	PropertyChanged.emit(propertyName, new_text)
