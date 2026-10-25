extends CardModuleProperty

class_name CardModuleEnumProperty



@export var option : OptionButton

func SetOptions(ops : PackedStringArray) -> void:
	for g in ops:
		g.rsplit()
		
		option.add_item(remove_ending(g))

func SetProperty(pName : String, value : Variant) -> void:
	super(pName, value)
	option.select(value)


func _on_option_button_item_selected(index: int) -> void:
	propertyValue = index
	PropertyChanged.emit(propertyName, index)

func remove_ending(text: String) -> String:
	var regex := RegEx.new()
	regex.compile(":\\d+$")
	return regex.sub(text, "")
