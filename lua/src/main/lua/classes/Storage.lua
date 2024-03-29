--[[

    foxbukkit-lua-lua - ${project.description}
    Copyright © ${year} Doridian (git@doridian.net)

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

]]
local Persister = require('Persister')

local rawget = rawget
local type = type
local next = next
local table_unpack = table.unpack

local _entity_mt = {
	__index = function(tbl, idx)
		if type(idx) == 'string' and idx:sub(1, 2) == '__' then
			return rawget(tbl, idx:sub(3))
		end

		local myValue = rawget(tbl, 'storage')[idx]
		if myValue ~= nil then
			return myValue
		end

		myValue = rawget(tbl, 'extensions')[idx]
		if myValue ~= nil then
			return myValue
		end

		local entity = rawget(tbl, 'entity')
		local entityValue = entity[idx]
		if entityValue and type(entityValue) == 'function' then
			return function(_, ...)
				local args = { ... }
				for k, v in next, args do
					if type(v) == 'table' and v.__entity then
						args[k] = v.__entity
					end
				end
				return entityValue(entity, table_unpack(args))
			end
		else
			return entityValue
		end
	end,
	__newindex = function(tbl, idx, value)
		local entity = rawget(tbl, 'entity')
		if entity[idx] ~= nil then
			entity[idx] = value
			return
		end
		rawget(tbl, 'storage')[idx] = value
		rawget(tbl, 'save')(tbl)
	end,
	__eq = function(o1, o2)
		local e1 = rawget(o1, 'entity')
		local e2 = rawget(o2, 'entity')
		if e1.Equals then
			return e1:Equals(e2)
		end
		return e1 == e2
	end,
	__metatable = false,
}

local _storage_mt = {
	__call = function(self, entity)
		if not entity then
			return nil
		end

		local entityID = entity[self.idFunction](entity)

		local storage = self.storageCache[entityID]
		if not storage then
			storage = self.persisthash and Persister:get(self.persisthash .. '_' .. tostring(entityID)) or {}
			self.storageCache[entityID] = storage
		end
		return setmetatable(
			{
				entity = entity,
				storage = storage,
				save = function()
					storage:__save()
				end,
				extensions = self.extensions,
			},
			_entity_mt
		)
	end,
	__newindex = function()
		error('Readonly')
	end,
	__metatable = false,
}

_storage_mt.__index = _storage_mt

return { create = function(_, idFunction, persisthash, extensions)
	return setmetatable(
		{
			extensions = extensions or {},
			persisthash = persisthash,
			storageCache = {},
			idFunction = idFunction,
		},
		_storage_mt
	)
end }
