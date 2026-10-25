extends FoldableCont

class_name CardModuleDescriptor

@export var modulePropertiesParent : Control

func GetModulePropertyParent() -> Control:
	return modulePropertiesParent

func _on_remove_pressed() -> void:
	var confirm = ConfirmationDialog.new()
	get_tree().root.add_child(confirm)
	confirm.popup_centered()
	confirm.title = ""
	confirm.dialog_text = "Remove Module ?"
	confirm.ok_button_text = "Yes"
	confirm.cancel_button_text = "No"
	confirm.confirmed.connect(RemoveConfirmed)

func RemoveConfirmed() -> void:
	queue_free()
	Remove.emit()
