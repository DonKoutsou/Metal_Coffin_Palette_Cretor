extends PanelContainer

class_name CardModuleProperty

@export var nameLabel : Label
@export var removeButton : Button

signal PropertyChanged(pName : String, newValue : Variant)
signal RemoveRequest(value : Variant)

var propertyName : String
var propertyValue : Variant

func SetMax(newMax : Variant) -> void:
	pass

func SetProperty(pName : String, value : Variant) -> void:
	propertyName = pName
	propertyValue = value
	nameLabel.text = CardHelper.prettify_class_name(pName)

func SetRemovable(t : bool) -> void:
	removeButton.visible = t


func _on_remove_pressed() -> void:
	RemoveRequest.emit(propertyValue)
