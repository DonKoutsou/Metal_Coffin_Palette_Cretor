extends PanelContainer

class_name FoldableCont

@export var container : Control

signal MoveUp
signal MoveDown
signal Remove
signal Add

var title : String :
	set(value):
		title = value
		$VBoxContainer/HBoxContainer/Expand.text = value

var folded : bool  = true:
	set(value):
		folded = value
		FoldToggled(value)

func DissableMoving() -> void:
	$VBoxContainer/HBoxContainer/MoveUp.hide()
	$VBoxContainer/HBoxContainer/MoveDown.hide()

func DissableAdding() -> void:
	$VBoxContainer/HBoxContainer/Add.hide()

func GetContainer() -> Control:
	return container

func _on_move_up_pressed() -> void:
	MoveUp.emit()

func _on_move_down_pressed() -> void:
	MoveDown.emit()

func _on_remove_pressed() -> void:
	Remove.emit()

func _on_expand_pressed() -> void:
	folded = !folded

func FoldToggled(t : bool) -> void:
	if (t):
		$VBoxContainer/HBoxContainer/Expand.icon = load("res://Scenes/FoldableContainer/Arrow.png")
	else:
		$VBoxContainer/HBoxContainer/Expand.icon = load("res://Scenes/FoldableContainer/Arrow2.png")
	GetContainer().get_parent().visible = !t

func _on_add_pressed() -> void:
	Add.emit()
