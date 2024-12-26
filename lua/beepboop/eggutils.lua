local M = {}

M.table_print = function(o)
	if type(o) == 'table' then
		local s = '{ '
		for k,v in pairs(o) do
			if type(k) ~= 'number' then k = '"'..k..'"' end
			s = s .. '['..k..'] = ' .. M.table_print(v) .. ','
		end
		return s .. '} '
	else
		return tostring(o)
	end
end

M.get_os = function()
	local binary_format = package.cpath:match("%p[\\|/]?%p(%a+)")
	if binary_format == "dll" then
		return "windows"
	elseif binary_format == "so" then
		return "linux"
	elseif binary_format == "dylib" then
		return "macos"
	else
		return nil
	end
end

M.has_value = function(list, val)
	for index, value in ipairs(list) do
		if value == val then
			return true
		end
	end
	return false
end

M.clamp = function(value, lower, upper)
	if value < lower then
	return lower
	elseif value > upper then
		return upper
	end
	return value
end

return M
