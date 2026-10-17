-- enum: the global Enum (Enums -> Enum -> EnumItem) built lazily from the generated API table.
do
	local format, freeze, err = string.format, table.freeze, H.err
	local TYPEOF = H.TYPEOF
	local API_ENUMS = H.API.enums

	local EIM = {} -- EnumItem
	TYPEOF[EIM] = "EnumItem"
	local EIMethods = {}
	EIM.__index = function(it, k)
		local m = EIMethods[k]
		if m then return m end
		err(format("%s is not a valid member of \"%s\"", tostring(k), tostring(it)))
		return nil
	end
	EIM.__newindex = function(_, k) err(format("%s cannot be assigned to", tostring(k))) end
	EIM.__tostring = function(it) return "Enum." .. it.EnumType.__name .. "." .. it.Name end
	function EIMethods.IsA(it, name) return it.EnumType.__name == name end

	local ENM = {} -- Enum
	TYPEOF[ENM] = "Enum"
	local ITEMS, LISTS, BYVALUE = {}, {}, {}
	local ENMethods = {}
	ENM.__index = function(e, k)
		local it = ITEMS[e][k]
		if it then return it end
		local m = ENMethods[k]
		if m then return m end
		err(format("%s is not a valid member of \"Enum.%s\"", tostring(k), e.__name))
		return nil
	end
	ENM.__newindex = function(_, k) err(format("%s cannot be assigned to", tostring(k))) end
	ENM.__tostring = function(e) return e.__name end
	function ENMethods.GetEnumItems(e)
		local out = {}
		for i, it in ipairs(LISTS[e]) do out[i] = it end
		return out
	end
	function ENMethods.FromName(e, n) return ITEMS[e][n] end
	function ENMethods.FromValue(e, v) return BYVALUE[e][v] end

	local cache = {}
	local function getEnum(name)
		local e = cache[name]
		if e ~= nil then return e end
		local src = API_ENUMS[name]
		if not src then cache[name] = false return false end
		e = setmetatable({ __name = name }, ENM)
		local items, list, byv = {}, {}, {}
		for part in src:gmatch("[^,]+") do
			local n, v = part:match("^(.-)=(%-?%d+)$")
			local it = freeze(setmetatable({ Name = n, Value = tonumber(v), EnumType = e }, EIM))
			items[n] = it
			list[#list + 1] = it
			if byv[it.Value] == nil then byv[it.Value] = it end
		end
		table.sort(list, function(a, b) return a.Value < b.Value end)
		ITEMS[e], LISTS[e], BYVALUE[e] = items, list, byv
		freeze(e)
		cache[name] = e
		return e
	end
	H.getEnum = getEnum
	function H.enumItem(enumName, itemName)
		local e = getEnum(enumName)
		return e and ITEMS[e][itemName] or nil
	end
	function H.isEnumItem(v) return getmetatable(v) == EIM end
	-- accept an EnumItem of the right enum, or its number value / string name (Roblox coerces both)
	function H.coerceEnum(enumName, v)
		local e = getEnum(enumName)
		if not e then return nil end
		if getmetatable(v) == EIM then
			if v.EnumType == e then return v end
			return nil
		end
		local t = type(v)
		if t == "number" then return BYVALUE[e][v] end
		if t == "string" then return ITEMS[e][v] end
		return nil
	end

	local ENSM = {} -- Enums
	TYPEOF[ENSM] = "Enums"
	local Enum = setmetatable({}, ENSM)
	ENSM.__index = function(_, k)
		if k == "GetEnums" then
			return function()
				local out = {}
				for n in pairs(API_ENUMS) do out[#out + 1] = getEnum(n) end
				return out
			end
		end
		local e = type(k) == "string" and getEnum(k)
		if e then return e end
		err(format("%s is not a valid member of \"Enums\"", tostring(k)))
		return nil
	end
	ENSM.__newindex = function(_, k) err(format("%s cannot be assigned to", tostring(k))) end
	ENSM.__tostring = function() return "Enums" end
	H.Enum = Enum
end
