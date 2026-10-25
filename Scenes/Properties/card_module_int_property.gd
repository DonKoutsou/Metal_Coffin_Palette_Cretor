extends CardModuleProperty

class_name CardModuleIntProperty

@export var box : SpinBox

func SetMax(newMax : Variant) -> void:
	box.max_value = newMax

func SetProperty(pName : String, value : Variant) -> void:
	super(pName, value)
	box.set_value_no_signal(value)


func _on_spin_box_value_changed(value: float) -> void:
	propertyValue = int(value)
	PropertyChanged.emit(propertyName, int(value))
