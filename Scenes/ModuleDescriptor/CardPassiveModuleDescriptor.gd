extends CardModuleDescriptor

class_name CardPassiveModuleDescriptor

@export var receiverOption : OptionButton
@export var targetOption : OptionButton
@export var ModuleName : Label

signal PassivePropertyChanged(pName : String, newValue : Variant)

func _ready() -> void:
	for g in Card_Passive.ReceiverType.size():
		receiverOption.add_item(Card_Passive.ReceiverType.keys()[g])
	
	for g in Card_Passive.TargetType.size():
		targetOption.add_item(Card_Passive.TargetType.keys()[g])

func ConfigurePassive(p : Card_Passive) -> void:
	receiverOption.select(p.Receiver)
	targetOption.select(p.Target)
	ModuleName.text = p.Module.get_script().get_global_name()


func _on_instigator_item_selected(index: int) -> void:
	PassivePropertyChanged.emit("Receiver", index)


func _on_target_item_selected(index: int) -> void:
	PassivePropertyChanged.emit("Target", index)
