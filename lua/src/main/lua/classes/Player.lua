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
local bukkitServer = require('Server'):getBukkitServer()
local UUID = bindClass('java.util.UUID')

local table_insert = table.insert
local type = type

local playerExt = {}

local playerStorage = require('Storage'):create('getUniqueId', 'player', playerExt)

local Player

local consoleCommandSender = bukkitServer:getConsoleSender()

local consolePlayer = {
	getName = function()
		return '[CONSOLE]'
	end,
	getDisplayName = function()
		return '[CONSOLE]'
	end,
	getUniqueId = function()
		return nil
	end,
	sendMessage = function(_, msg)
		return consoleCommandSender:sendMessage(msg)
	end,
}

local findConstraints

findConstraints = {
	excludePlayer = function(excludeply)
		return function(ply)
			return ply ~= excludeply
		end
	end,
	matchPlayer = function(matchply)
		return function(ply)
			return ply == matchply
		end
	end,
	matchName = function(match)
		match = match:lower()
		local matchFirst = match:sub(1, 1)
		if matchFirst == '@' then
			return findConstraints.matchPlayer(playerStorage(bukkitServer:getPlayerExact(match:sub(2))))
		elseif matchFirst == '*' then
			match = match:sub(2)
		elseif matchFirst == '$' then
			return findConstraints.matchPlayer(Player:getByUUID(match:sub(2)))
		end

		if match:len() < 1 then return end

		return function(ply)
			local nickName = ply.getNickName and ply:getNickName() or ply:getDisplayName()
			return ply:getName():lower():find(match, 1, true) or (nickName and nickName:stripColors():lower():find(
				match,
				1,
				true
			))
		end
	end,
	immunityRestrictionLevel = function(level, delta)
		return function(ply)
			return ply:fitsImmunityRequirement(level, delta)
		end
	end,
	immunityRestrictionPlayer = function(compateTo, delta)
		return function(ply)
			return ply == compateTo or compateTo:fitsImmunityRequirement(ply, delta)
		end
	end,
	permissionRestriction = function(permission)
		return function(ply)
			return ply:hasPermission(permission)
		end
	end,
	andConstraint = function(...)
		local args = { ... }
		if type(args[1]) == 'table' then
			args = args[1]
		end
		return function(ply)
			for _, constraint in next, args do
				if not constraint(ply) then
					return false
				end
			end
			return true
		end
	end,
	orConstraint = function(...)
		local args = { ... }
		if type(args[1]) == 'table' then
			args = args[1]
		end
		return function(ply)
			for _, constraint in next, args do
				if constraint(ply) then
					return true
				end
			end
			return false
		end
	end,
}

Player = {
	getByUUID = function(_, uuid)
		if type(uuid) == 'string' then
			uuid = UUID:fromString(uuid)
		end
		return playerStorage(bukkitServer:getPlayer(uuid))
	end,
	constraints = findConstraints,
	getAll = function()
		local players = {}
		local iter = bukkitServer:getOnlinePlayers()
		if not iter.length then
			iter = iter:iterator()
			while iter:hasNext() do
				table_insert(players, playerStorage(iter:next()))
			end
		else
			for i = 1, #iter do
				table_insert(players, playerStorage(iter[i]))
			end
		end
		return players
	end,
	findSingle = function(self, constraint)
		local matches = self:find(constraint, true)
		if #matches ~= 1 then
			return nil
		end
		return matches[1]
	end,
	find = function(self, constraint, forbidMultiple)
		local availablePlayers = self:getAll()

		local matches = {}
		for _, ply in next, availablePlayers do
			if constraint(ply) then
				table_insert(matches, ply)
			end
		end

		if forbidMultiple and #matches ~= 1 then
			return {}
		end

		return matches
	end,
	extend = function(_, player)
		return playerStorage(player)
	end,
	getConsole = function()
		return consolePlayer
	end,
	addConsoleExtensions = function(_, extensions)
		for k, v in next, extensions do
			consolePlayer[k] = v
		end
	end,
	addExtensions = function(_, extensions)
		for k, v in next, extensions do
			playerExt[k] = v
		end
	end,
}

return Player
