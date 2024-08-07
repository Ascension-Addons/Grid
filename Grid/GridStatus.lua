--[[--------------------------------------------------------------------
	GridStatus.lua
----------------------------------------------------------------------]]

local _, ns = ...
local L = ns.L

local GridRoster = Grid:GetModule("GridRoster")

local GridStatus = Grid:NewModule("GridStatus", "AceModuleCore-2.0")
GridStatus:SetModuleMixins("AceDebug-2.0", "AceEvent-2.0")

--{{{ Module prototype

GridStatus.modulePrototype.core = GridStatus

function GridStatus.modulePrototype:OnInitialize()
	if not self.db then
		self.core.core:RegisterDefaults(self.name, "profile", self.defaultDB or {})
		self.db = self.core.core:AcquireDBNamespace(self.name)
	end
	self.debugging = self.db.profile.debug
	self.debugFrame = GridStatus.debugFrame

	-- replace UnregisterEvent with our own
	self.__UnregisterEvent = self.UnregisterEvent
	self.UnregisterEvent = self._UnregisterEvent
end

function GridStatus.modulePrototype:OnEnable()
	for status, module in GridStatus:RegisteredStatusIterator() do
		if module == self.name and self.db.profile[status] then
			if self.db.profile[status].enable and self['OnStatusEnable'] then
				self:OnStatusEnable(status)
			end
		end
	end
end

function GridStatus.modulePrototype:OnDisable()
	for status, module in GridStatus:RegisteredStatusIterator() do
		if module == self.name and self.db.profile[status] then
			if self.db.profile[status].enable and self['OnStatusDisable'] then
				self:OnStatusDisable(status)
			end
		end
	end
end

function GridStatus.modulePrototype:_UnregisterEvent(event)
	if self:IsEventRegistered(event) then
		self:__UnregisterEvent(event)
	end
end

function GridStatus.modulePrototype:Reset()
	self.debugging = self.db.profile.debug
	self:Debug("Reset")
end

function GridStatus.modulePrototype:InitializeOptions()
	GridStatus:Debug("InitializeOptions", self.name)
	if not self.options then
		self.options = {
			type = "group",
			name = self.menuName or self.name,
			desc = string.format(L["Options for %s."], self.name),
			args = {},
		}
	end
	if self.extraOptions then
		for name, option in pairs(self.extraOptions) do
			self.options.args[name] = option
		end
	end
end

function GridStatus.modulePrototype:RegisterStatus(status, desc, options, inMainMenu, order)
	GridStatus:RegisterStatus(status, desc, self.name or true)

	local optionMenu
	if inMainMenu then
		optionMenu = GridStatus.options.args
	else
		if not self.options then
			self:InitializeOptions()
		end
		GridStatus.options.args[self.name] = self.options
		optionMenu = self.options.args
	end

	local module = self
	if not optionMenu[status] then
		optionMenu[status] = {
			type = "group",
			name = desc,
			desc = string.format(L["Status: %s"], desc),
			order = inMainMenu and 111 or order,
			args = {
				["color"] = {
					type = "color",
					name = L["Color"],
					desc = string.format(L["Color for %s"], desc),
					order = 90,
					hasAlpha = true,
					get = function()
						local color = module.db.profile[status].color
						return color.r, color.g, color.b, color.a
					end,
					set = function(r, g, b, a)
						local color = module.db.profile[status].color
						color.r = r
						color.g = g
						color.b = b
						color.a = a or 1

                        GridStatus:TriggerEvent("Grid_ColorsChanged")
					end,
				},
				["priority"] = {
					type = "range",
					name = L["Priority"],
					desc = string.format(L["Priority for %s"], desc),
					order = 91,
					max = 99,
					min = 0,
					step = 1,
					get = function()
						return module.db.profile[status].priority
					end,
					set = function(v)
						module.db.profile[status].priority = v
					end,
				},
				["Header"] = {
					type = "header",
					order = 110,
				},
				["range"] = {
					type = "toggle",
					name = L["Range filter"],
					desc = string.format(L["Range filter for %s"], desc),
					order = 111,
					get = function() return module.db.profile[status].range end,
					set = function()
						module.db.profile[status].range = not module.db.profile[status].range
					end,
				},
				["enable"] = {
					type = "toggle",
					name = L["Enable"],
					desc = string.format(L["Enable %s"], desc),
					order = 112,
					get = function()
						return module.db.profile[status].enable
					end,
					set = function(v)
						module.db.profile[status].enable = v
							if v then
								if module['OnStatusEnable'] then
									module:OnStatusEnable(status)
								end
							else
								if module['OnStatusDisable'] then
									module:OnStatusDisable(status)
								end
							end
					end,
				},
			},
		}

		if options then
			for name, option in pairs(options) do
				if not option then
					optionMenu[status].args[name] = nil
				else
					optionMenu[status].args[name] = option
				end
			end
		end

	end
end

function GridStatus.modulePrototype:UnregisterStatus(status)
	GridStatus:UnregisterStatus(status, (self.name or true))
end

--}}}

--{{{ AceDB defaults

GridStatus.defaultDB = {
	debug = false,
	range = false,
	colors = {
		PetColorType = "Using Fallback color",
		UNKNOWN_UNIT = { r = 0.5, g = 0.5, b = 0.5, a = 1 },
		UNKNOWN_PET = { r = 0, g = 1, b = 0, a = 1 },
		[L["Beast"]] = { r = 0.93725490196078, g = 0.75686274509804, b = 0.27843137254902, a = 1 },
		[L["Demon"]] = { r = 0.54509803921569, g = 0.25490196078431, b = 0.68627450980392, a = 1 },
		[L["Humanoid"]] = { r = 0.91764705882353, g = 0.67450980392157, b = 0.84705882352941, a = 1 },
		[L["Undead"]] = { r = 0.8, g = 0.2, b = 0, a = 1 },
		[L["Dragonkin"]] = { r = 0.8, g = 0.8, b = 0.8, a = 1 },
		[L["Elemental"]] = { r = 0.8, g = 1, b = 1, a = 1 },
		-- I think this was flying carpets
		[L["Not specified"]] = { r = 0.4, g = 0.4, b = 0.4, a = 1 },
	},
}

--}}}
--{{{ AceOptions table

local PRIMARY_STAT_NAME_AND_COLORS = {
    {
        name = "Primary Stat: Strength",
        color = { r = 0.78, g = 0.61, b = 0.43, a = 1 }
    },
    {
        name = "Primary Stat: Agility",
        color = { r = 1, g = 0.96, b = 0.41, a = 1 }
    },
    {
        name = "Primary Stat: Intellect",
        color = { r = 0.25, g = 0.78, b = 0.92, a = 1 }
    },
    {
        name = "Primary Stat: Spirit",
        color = { r = 1, g = 1, b = 1, a = 1 }
    }
}

GridStatus.options = {
	type = "group",
	name = L["Status"],
	desc = string.format(L["Options for %s."], GridStatus.name),
	args = {
		["color"] = {
			type = "group",
			name = L["Colors"],
			desc = L["Color options for class and pets."],
			order = -1,
			args = {
				["fallback"] = {
					type = "group",
					name = L["Fallback colors"],
					desc = L["Color of unknown units or pets."],
					args = {
						["unit"] = {
							type = "color",
							name = L["Unknown Unit"],
							desc = L["The color of unknown units."],
							order = 100,
							get = function()
									local c = GridStatus.db.profile.colors.UNKNOWN_UNIT
									return c.r, c.g, c.b, c.a
								end,
							set = function(r, g, b, a)
									local c = GridStatus.db.profile.colors.UNKNOWN_UNIT
									c.r, c.g, c.b, c.a = r, g, b, a
									GridStatus:TriggerEvent("Grid_ColorsChanged")
								end,
							hasAlpha = false,
						},
						["pet"] = {
							type = "color",
							name = L["Unknown Pet"],
							desc = L["The color of unknown pets."],
							order = 100,
							get = function()
									local c = GridStatus.db.profile.colors.UNKNOWN_PET
									return c.r, c.g, c.b, c.a
								end,
							set = function(r, g, b, a)
									local c = GridStatus.db.profile.colors.UNKNOWN_PET
									c.r, c.g, c.b, c.a = r, g, b, a
									GridStatus:TriggerEvent("Grid_ColorsChanged")
								end,
							hasAlpha = false,
						},
					},
				},
				["class"] = {
					type = "group",
					name = L["Class colors"],
					desc = L["Color of player unit classes."],
					args = {
					},
				},
                ["primarystat"] = {
					type = "group",
					name = L["Primary stat colors"],
					desc = L["Color of player unit primary stats."],
					args = {
                    },
				},
				["creaturetype"] = {
					type = "group",
					name = L["Creature type colors"],
					desc = L["Color of pet unit creature types."],
					args = {
					},
				},
				["petcolortype"] = {
					type = "text",
					name = L["Pet coloring"],
					desc = L["Set the coloring strategy of pet units."],
					order = 200,
					get = function()
							return GridStatus.db.profile.colors.PetColorType
						end,
					set = function(v)
							GridStatus.db.profile.colors.PetColorType = v
							GridStatus:TriggerEvent("Grid_ColorsChanged")
						end,
					validate = {
                        ["By Owner Class"] = L["By Owner Class"],
                        ["By Owner Primary stat"] = L["By Owner Primary stat"],
                        ["By Creature Type"] = L["By Creature Type"],
                        ["Using Fallback color"] = L["Using Fallback color"]
                    },
				},
			},
		},
		["Header"] = {
			type = "header",
			order = 110,
		},
	},
}

--}}}

function GridStatus:FillColorOptions(options)
	local classEnglishToLocal = {}
	FillLocalizedClassList(classEnglishToLocal, false)

	local colors = self.db.profile.colors
	for class, color in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
		if not colors[class] then
			colors[class] = { r = color.r, g = color.g, b = color.b }
		end
		local classLocal = classEnglishToLocal[class]
		options.args.class.args[class] = {
			type = "color",
			name = classLocal,
			desc = L["Color for %s."]:format(classLocal),
			get = function()
				local c = colors[class]
				return c.r, c.g, c.b
			end,
			set = function(r, g, b)
				local c = colors[class]
				c.r, c.g, c.b = r, g, b
				GridStatus:TriggerEvent("Grid_ColorsChanged")
			end,
		}
	end

	options.args.class.args["Header"] = {
		type = "header",
		order = 110,
	}
	options.args.class.args["resetclasscolors"] = {
		type = "execute",
		name = L["Reset class colors"],
		desc = L["Reset class colors to defaults."],
		order = 111,
		func = function() GridStatus:ResetClassColors() end,
	}

	-- wtf, this is ugly... refactor!
	for _, class in ipairs{ L["Beast"], L["Demon"], L["Humanoid"], L["Undead"], L["Dragonkin"], L["Elemental"], L["Not specified"] } do
		options.args.creaturetype.args[class] = {
			type = "color",
			name = class,
			desc = L["Color for %s."]:format(class),
			get = function()
				local c = colors[class]
				return c.r, c.g, c.b
			end,
			set = function(r, g, b)
				local c = colors[class]
				c.r, c.g, c.b = r, g, b
				GridStatus:TriggerEvent("Grid_ColorsChanged")
			end,
		}
	end

    for _, ps in pairs(PRIMARY_STAT_NAME_AND_COLORS) do
        local name = ps.name
        local color = ps.color
		if not colors[name] then
			colors[name] = { r = color.r, g = color.g, b = color.b }
		end
		options.args.primarystat.args[name] = {
			type = "color",
			name = string.sub(name,15,-1),
			desc = L["Color for %s."]:format(name),
			get = function()
				local c = colors[name]
				return c.r, c.g, c.b
			end,
			set = function(r, g, b)
				local c = colors[name]
				c.r, c.g, c.b = r, g, b
				GridStatus:TriggerEvent("Grid_ColorsChanged")
			end,
		}
	end

    options.args.primarystat.args["Header"] = {
		type = "header",
		order = 110,
	}
    options.args.primarystat.args["resetprimarystatcolors"] = {
		type = "execute",
		name = L["Reset Primary stat colors"],
		desc = L["Reset Primary stat colors to defaults."],
		order = 111,
		func = function() GridStatus:ResetPrimaryStatColors() end,
	}
end

function GridStatus:ResetClassColors()
	local colors = self.db.profile.colors
	for class, class_color in pairs(CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS) do
		local c = colors[class]
		c.r, c.g, c.b = class_color.r, class_color.g, class_color.b
	end
	GridStatus:TriggerEvent("Grid_ColorsChanged")
end

function GridStatus:ResetPrimaryStatColors()
	local colors = self.db.profile.colors
	for _, ps in pairs(PRIMARY_STAT_NAME_AND_COLORS) do
        local name = ps.name
        local color = ps.color
        local c = colors[name]
		c.r, c.g, c.b = color.r, color.g, color.b
	end
	GridStatus:TriggerEvent("Grid_ColorsChanged")
end

function GridStatus:OnInitialize()
	self.super.OnInitialize(self)
	self.registry = {}
	self.registryDescriptions = {}
	self.cache = {}
	self:FillColorOptions(self.options.args.color)
end

function GridStatus:OnEnable()
	self.super.OnEnable(self)
	self:RegisterEvent("Grid_UnitLeft", "RemoveFromCache")
end

function GridStatus:Reset()
	self.super.Reset(self)
	self:FillColorOptions(self.options.args.color)
	GridStatus:TriggerEvent("Grid_ColorsChanged")
end

--{{{ Status registry

function GridStatus:RegisterStatus(status, description, moduleName)
	if not self.registry[status] then
		self:Debug("Registered", status, "("..description..")", "for", moduleName)
		self.registry[status] = (moduleName or true)
		self.registryDescriptions[status] = description
		self:TriggerEvent("Grid_StatusRegistered", status, description, moduleName)
	else
		-- error if status is already registered?
		self:Debug("RegisterStatus:", status, "is already registered.")
	end
end

function GridStatus:UnregisterStatus(status, moduleName)
	local name

	if self:IsStatusRegistered(status) then
		self:Debug("Unregistered", status, "for", moduleName)
		-- need to remove from cache
		for guid in pairs(self.cache) do
			self:SendStatusLost(guid, status)
		end

		-- now we can remove from registry
		self.registry[status] = nil
		self.registryDescriptions[status] = nil
		self:TriggerEvent("Grid_StatusUnregistered", status)
	end
end

function GridStatus:IsStatusRegistered(status)
	return (self.registry and
		self.registry[status] and
		true)
end

function GridStatus:RegisteredStatusIterator()
	local status
	local gsreg = self.registry
	local gsregdescr = self.registryDescriptions
	return function()
		status = next(gsreg, status)
		return status, gsreg[status], gsregdescr[status]
	end
end

--}}}
--{{{ Caching status functions

function GridStatus:SendStatusGained(guid, status, priority, range, color, text,  value, maxValue, texture, start, duration, stack)
	if not guid then return end

	local cache = self.cache
	local cached

	if color and not type(color) == "table" then
		self:Debug("color is not a table for", status)
	end

	if range and type(range) ~= "number" then
		self:Debug("Range is not a number for", status)
	end

	if text == nil then
		text = ""
	end

	-- create cache for unit if needed
	if not cache[guid] then
		cache[guid] = {}
	end

	if not cache[guid][status] then
		cache[guid][status] = {}
	end

	cached = cache[guid][status]

	-- if no changes were made, return rather than triggering an event
	if cached and
		cached.priority == priority and
		cached.range == range and
		cached.color == color and
		cached.text == text and
		cached.value == value and
		cached.maxValue == maxValue and
		cached.texture == texture and
		cached.start == start and
		cached.duration == duration and
		cached.stack == stack then

		return
	end

	-- update cache
	cached.priority = priority
	cached.range = range
	cached.color = color
	cached.text = text
	cached.value = value
	cached.maxValue = maxValue
	cached.texture = texture
	cached.start = start
	cached.duration = duration
	cached.stack = stack

	self:TriggerEvent("Grid_StatusGained", guid, status, priority, range, color, text, value, maxValue, texture, start, duration, stack)
end

function GridStatus:SendStatusLost(guid, status)
	if not guid then return end

	-- if status isn't cached, don't send status lost event
	if (not self.cache[guid]) or (not self.cache[guid][status]) then
		return
	end

	self.cache[guid][status] = nil

	self:TriggerEvent("Grid_StatusLost", guid, status)
end

function GridStatus:SendStatusLostAllUnits(status)
	for guid in pairs(self.cache) do
		self:SendStatusLost(guid, status)
	end
end

function GridStatus:RemoveFromCache(guid)
	self.cache[guid] = nil
end

function GridStatus:GetCachedStatus(guid, status)
	local cache = self.cache
	return (cache[guid] and cache[guid][status])
end

function GridStatus:CachedStatusIterator(status)
	local cache = self.cache
	local guid

	if status then
		-- iterator for a specific status
		return function()
			guid = next(cache, guid)

			-- we reached the end early?
			if guid == nil then
				return nil
			end

			while cache[guid][status] == nil do
				guid = next(cache, guid)

				if guid == nil then
					return nil
				end
			end

			return guid, status, cache[guid][status]
		end
	else
		-- iterator for all units, all statuses
		return function()
			status = next(cache[guid], status)

			-- find the next unit with a status
			while not status do
				guid = next(cache, guid)

				if guid then
					status = next(cache[guid], status)
				else
					return nil
				end
			end

			return guid, status, cache[guid][status]
		end
	end
end

--}}}
--{{{ Unit Colors

function GridStatus:UnitColor(guid, settings)
	local unitid = GridRoster:GetUnitidByGUID(guid)
	if not unitid then
		-- bad news if we can't get a unitid
		return
	end

	local colors = self.db.profile.colors
	local owner = GridRoster:GetOwnerUnitidByUnitid(unitid)

	if owner then
		-- if it has an owner, then it's a pet
		local petColorType = colors.PetColorType
		if petColorType == "By Owner Class" then
			local _, owner_class = UnitClass(owner)
			if owner_class then
				return colors[owner_class]
			end
        elseif petColorType == "By Owner Primary stat" then
            local owner_ps = GetUnitPrimaryStat(owner)
            if owner_ps then
                return colors[PRIMARY_STAT_NAME_AND_COLORS[owner_ps].name]
            end
		elseif petColorType == "By Creature Type" then
			local creature_type = UnitCreatureType(unitid)
			-- note that creature_type is nil for Shadowfiends
			if creature_type and colors[creature_type] then
				return colors[creature_type]
			end
		end

		return colors.UNKNOWN_PET
	end

    if settings.colorType == "Use custom color" then
        return settings.color
    elseif settings.colorType == "Use primary stat color" then
        local ps = GetUnitPrimaryStat(unitid)
        if ps then
            return colors[PRIMARY_STAT_NAME_AND_COLORS[ps].name]
        end
    elseif settings.colorType == "Use class color" then
        local _, class = UnitClass(unitid)
        if class then
            return colors[class]
        end
    end

	return colors.UNKNOWN_UNIT
end

--}}}
