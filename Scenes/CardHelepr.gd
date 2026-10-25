extends RefCounted

class_name CardHelper

#----------------------------------------------------------------------
##Passes both files through a hash function and checks the resault
static func _files_are_identical(file_a: String,file_b: String) -> bool:

	var hash_a := FileAccess.get_sha256(file_a)
	var hash_b := FileAccess.get_sha256(file_b)

	return hash_a == hash_b

#----------------------------------------------------------------------
static func prettify_class_name(clName: String) -> String:
	var regex := RegEx.new()
	regex.compile("(?<!^)([A-Z])")
	return regex.sub(clName, " $1", true)

#----------------------------------------------------------------------
static func get_exported_enum_data(prop_dict: Dictionary) -> PackedStringArray:
	var enum_data : PackedStringArray = []
	
	if prop_dict.hint == PROPERTY_HINT_ENUM:
		var keys = prop_dict.hint_string.split(",")
		
		for i in keys.size():
			enum_data.append(keys[i])
			
	return enum_data

#----------------------------------------------------------------------
static func get_exported_enum_data_from_hint(hint: String) -> PackedStringArray:
	var enum_data : PackedStringArray = []

	var keys = hint.split(",")
	
	for i in keys.size():
		enum_data.append(keys[i])
			
	return enum_data

#----------------------------------------------------------------------
static func get_uid_from_tres(path: String) -> String:
	if not FileAccess.file_exists(path):
		return ""

	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	var header := file.get_line()
	file.close()

	var regex := RegEx.new()
	regex.compile('uid="(uid://[^"]+)"')

	var result := regex.search(header)
	if result:
		return result.get_string(1)

	return ""

#----------------------------------------------------------------------
static func write_uid_to_tres(path: String, uid: String) -> bool:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false

	var content := file.get_as_text()
	file.close()

	var regex := RegEx.new()
	regex.compile('(?m)^\\[gd_resource([^\\]]*)\\]')

	var match_result := regex.search(content)
	if match_result == null:
		return false

	var header := match_result.get_string(0)
	var attributes := match_result.get_string(1)

	# Remove any existing UID attribute.
	var uid_regex := RegEx.new()
	uid_regex.compile('\\s+uid="[^"]*"')
	attributes = uid_regex.sub(attributes, "", true)

	# Add the new UID.
	attributes += ' uid="' + uid + '"'

	content = content.replace(
		header,
		"[gd_resource" + attributes + "]"
	)

	file = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return false
		
	var fixed_text := restore_dependency_uids(content)
	file.store_string(fixed_text)
	
	file.close()
	return true

#--------------------------------------------------------
## Goes through each dependency, tries to recover their UID and put it into the .tres file
##This is to be used for .tres files that lose the UID of their dependencies when loaded through a pck
static func restore_dependency_uids(text: String) -> String:
	var path_regex := RegEx.new()
	path_regex.compile('path="([^"]+)"')

	var output := PackedStringArray()

	for line in text.split("\n"):
		if line.begins_with("[ext_resource ") \
		and not line.contains('uid="'):
			var match_result := path_regex.search(line)

			if match_result:
				var path := match_result.get_string(1)
				var uid := ResourceLoader.get_resource_uid(path)

				if uid != ResourceUID.INVALID_ID:
					var uid_text := ResourceUID.id_to_text(uid)
					line = line.replace(
						'path="',
						'uid="%s" path="' % uid_text
					)

		output.append(line)

	return "\n".join(output)
