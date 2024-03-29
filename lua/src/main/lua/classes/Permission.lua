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
local permissionsAPI = __LUA_STATE:getEnhancedPermissionManager()

local Player = require('Player')
local Permission

local tostring = tostring
local type = type

local immunity = {
	GREATER = 1,
	LESS = -1,
	EQUAL = 0,
	GREATER_OR_EQUAL = 2,
	LESS_OR_EQUAL = -2,
}

Player:addExtensions{
	compareImmunityLevel = function(self, other)
		return Permission:compareImmunityLevel(self, other)
	end,
	fitsImmunityRequirement = function(self, other, requirement)
		return Permission:fitsImmunityRequirement(self, other, requirement)
	end,
	getImmunityLevel = function(self)
		return Permission:getImmunityLevel(self)
	end,
	getGroup = function(self)
		return Permission:getGroup(self)
	end,
}

Player:addConsoleExtensions{
	compareImmunityLevel = function()
		return Permission.Immunity.GREATER
	end,
	fitsImmunityRequirement = function(_, _, requirement)
		return requirement == immunity.GREATER or requirement == immunity.GREATER_OR_EQUAL
	end,
	getImmunityLevel = function()
		return 9999
	end,
	getGroup = function()
		return 'console'
	end,
	hasPermission = function()
		return true
	end,
}

if not permissionsAPI then
	Permission = {
		Immunity = immunity,
		getImmunityLevel = function()
			return 0
		end,
		getGroupImmunityLevel = function()
			return 0
		end,
		getGroup = function()
			return 'default'
		end,
		setGroup = function() end,
		isAvailable = function()
			return false
		end,
		fitsImmunityRequirement = function()
			return true
		end,
		compareImmunityLevel = function()
			return immunity.EQUAL
		end,
	}
	return Permission
end

local UUID = bindClass('java.util.UUID')

local function fixPlyOrUUID(ply_or_uuid)
	if type(ply_or_uuid) == 'string' then
		return UUID:fromString(ply_or_uuid)
	elseif ply_or_uuid.__entity then
		return ply_or_uuid.__entity
	end
	return ply_or_uuid
end

Permission = {
	Immunity = immunity,
	getImmunityLevel = function(_, ply_or_uuid)
		return permissionsAPI:getImmunityLevel(fixPlyOrUUID(ply_or_uuid))
	end,
	getGroupImmunityLevel = function(_, group)
		return permissionsAPI:getImmunityLevel(tostring(group))
	end,
	getGroup = function(_, ply_or_uuid)
		return permissionsAPI:getGroup(fixPlyOrUUID(ply_or_uuid))
	end,
	setGroup = function(_, ply_or_uuid, group)
		return permissionsAPI:setGroup(fixPlyOrUUID(ply_or_uuid), group)
	end,
	isAvailable = function()
		return permissionsAPI:isAvailable()
	end,
	fitsImmunityRequirement = function(self, ply_or_uuid1, ply_or_uuid2, requirement)
		local diff = self:compareImmunityLevel(ply_or_uuid1, ply_or_uuid2)
		if requirement == immunity.GREATER_OR_EQUAL then
			return diff == immunity.EQUAL or diff == immunity.GREATER
		elseif requirement == immunity.LESS_OR_EQUAL then
			return diff == immunity.EQUAL or diff == immunity.LESS
		else
			return requirement == diff
		end
	end,
	compareImmunityLevel = function(self, ply_or_uuid1, ply_or_uuid2)
		local level1 = self:getImmunityLevel(ply_or_uuid1)
		local level2 = self:getImmunityLevel(ply_or_uuid2)
		if level1 > level2 then
			return immunity.GREATER
		elseif level1 < level2 then
			return immunity.LESS
		else
			return immunity.EQUAL
		end
	end,
}

return Permission
