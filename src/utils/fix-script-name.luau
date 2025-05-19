local function fix_script_name(name: string)
	name = string.lower(name)
	name = string.gsub(name, "&", "ampersand")
	return name
end

return fix_script_name
