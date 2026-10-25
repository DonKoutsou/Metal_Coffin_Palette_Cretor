extends CardModuleIntProperty

class_name CardModuleFloatProperty

func _on_spin_box_value_changed(value: float) -> void:
	propertyValue = value
	PropertyChanged.emit(propertyName, value)
