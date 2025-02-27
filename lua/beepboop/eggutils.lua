local M = {}

M.has_value = function(list, val)
	for _, value in ipairs(list) do
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
