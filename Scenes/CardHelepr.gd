extends RefCounted

class_name CardHelper



#----------------------------------------------------------------------
##Passes both files through a hash function and checks the resault
static func _files_are_identical(file_a: String,file_b: String) -> bool:

	var hash_a := FileAccess.get_sha256(file_a)
	var hash_b := FileAccess.get_sha256(file_b)

	return hash_a == hash_b

#----------------------------------------------------------------------
static func replace_class_source(original_path: String ,external_path: String) -> Error:
	var original : Script = ResourceLoader.load(original_path)
	if original == null:
		return ERR_CANT_OPEN

	var file := FileAccess.open(external_path, FileAccess.READ)
	if file == null:
		return ERR_CANT_OPEN

	var new_source = file.get_as_text()
	file.close()
	
	var originalSource : String = original.source_code
	var dif : bool = _files_are_identical(originalSource, new_source)
	
	if (dif):
		original.source_code = new_source
		var error = original.reload(true)
		print("Script Replaced {0}".format([original_path.get_file()]))
		return error
			
	return ERR_ALREADY_EXISTS

#----------------------------------------------------------------------
##Returns the class name of the script without loading it
static func get_class_name_from_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("class_name "):
			return line.trim_prefix("class_name ").split(" ")[0]

	return ""

#----------------------------------------------------------------------
##Returns the class the provided script file extends from without loading it
static func get_extended_class_from_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""

	while not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.begins_with("extends "):
			return line.trim_prefix("extends ").split(" ")[0]

	return ""

#----------------------------------------------------------------------
##Tries to recover the returned value of a function from a script file without loading it
func get_function_return_from_file(path: String, function_name: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var inside_function := false
	var indent_level := -1

	while not file.eof_reached():
		var line := file.get_line()
		var trimmed := line.strip_edges()

		if not inside_function:
			if trimmed.begins_with("func " + function_name + "("):
				inside_function = true
				indent_level = line.length() - line.lstrip(" \t").length()
			continue

		# Stop when another function or same-level declaration begins.
		var current_indent := line.length() - line.lstrip(" \t").length()
		if trimmed.begins_with("func ") and current_indent <= indent_level:
			break

		if trimmed.begins_with("return "):
			var value_text := trimmed.trim_prefix("return ").strip_edges()

			if value_text.is_valid_int():
				return value_text.to_int()
			if value_text.is_valid_float():
				return value_text.to_float()
			if value_text == "true":
				return true
			if value_text == "false":
				return false
			if value_text == "null":
				return null
			if value_text.begins_with('"') and value_text.ends_with('"'):
				return value_text.substr(1, value_text.length() - 2)

			return value_text

	return null

#----------------------------------------------------------------------
##Returns the value of a variable from a script file without loading it
func get_variable_from_file(path: String, variable_name: String) -> Variant:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return null

	var prefix := "var " + variable_name
	var static_prefix := "static var " + variable_name

	while not file.eof_reached():
		var line := file.get_line().strip_edges()

		if line.begins_with(prefix) or line.begins_with(static_prefix):
			var parts := line.split("=", true, 1)
			if parts.size() < 2:
				return null

			var value_text := parts[1].strip_edges()

			# Handle simple literal values.
			if value_text.is_valid_int():
				return value_text.to_int()
			if value_text.is_valid_float():
				return value_text.to_float()
			if value_text == "true":
				return true
			if value_text == "false":
				return false
			if value_text == "null":
				return null
			if value_text.begins_with('"') and value_text.ends_with('"'):
				return value_text.substr(1, value_text.length() - 2)

			return value_text

	return null

#----------------------------------------------------------------------
static func get_all_script_variables(res : Resource) -> Array[Dictionary]:
	return res.get_property_list().filter(func(prop):
		return prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE
	)

#----------------------------------------------------------------------
static func _inherits_from(clName: String,target_class: String,classes: Dictionary[String, Dictionary]) -> bool:
	var current: String = clName

	while classes.has(current):
		var base: String = classes[current]["base"]

		if base == target_class:
			return true

		current = base

	return false

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
