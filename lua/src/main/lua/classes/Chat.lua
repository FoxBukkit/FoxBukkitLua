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
local chatAPI = __LUA_STATE:getEnhancedChatMessageManager()

local Player = require('Player')

Player:addConsoleExtensions{
	sendReply = function(self, message)
		return self:sendMessage('[FB] ' .. message)
	end,
	sendError = function(self, message)
		return self:sendMessage('[FB] [ERROR] ' .. message)
	end,
}

if not chatAPI then
	local bukkitServer = require('Server'):getBukkitServer()

	local Chat = {
		isAvailable = function()
			return false
		end,
		getConsole = Player.getConsole,
		makeButton = function(_, command, label, _, _, _)
			return '<BUTTON:' .. command .. '>' .. label .. '</BUTTON>'
		end,
		getPlayerUUID = function()
			return nil
		end,
		sendGlobal = function(_, _, _, content)
			bukkitServer:broadcastMessage(content)
		end,
		broadcastLocal = function(_, _, content)
			bukkitServer:broadcastMessage(content)
		end,
		sendLocalToPlayer = function(_, source, content, target)
			if target then
				target:sendMessage(content)
			else
				-- content, target
				content:sendMessage(source)
			end
		end,
		sendLocalToPermission = function(_, source, content, target)
			if target then
				bukkitServer:broadcastMessage('$' + target, content)
			else
				-- content, target
				bukkitServer:broadcastMessage('$' + content, source)
			end
		end,
		sendLocal = function(_, _, content, chatTarget, targetFilter)
			bukkitServer:broadcastMessage('!' .. tostring(targetFilter) .. '!' .. tostring(chatTarget), content)
		end,
		getPlayerNick = function(_, ply_or_uuid)
			return ply_or_uuid:getDisplayName()
		end,
	}

	Player:addExtensions{
		sendXML = function(self, message)
			return Chat:sendLocalToPlayer(message, self)
		end,
		sendReply = function(self, message)
			return self:sendXML('[FB] ' .. message)
		end,
		sendError = function(self, message)
			return self:sendXML('[FB] [ERROR] ' .. message)
		end,
		getNickName = function(self)
			return self:getDisplayName()
		end,
	}

	return Chat
end

local function fixPly(ply)
	if ply and ply.__entity then
		return ply.__entity
	end
	return ply
end

local Chat = {
	isAvailable = function()
		return chatAPI:isAvailable()
	end,
	getConsole = function()
		return chatAPI:getConsole()
	end,
	makeButton = function(_, command, label, color, run, addHover)
		return chatAPI:makeButton(command, label, color, run, (addHover ~= false))
	end,
	getPlayerUUID = function(_, name)
		return chatAPI:getPlayerUUID(name)
	end,
	sendGlobal = function(_, source, type, content)
		return chatAPI:sendGlobal(fixPly(source), type, content)
	end,
	broadcastLocal = function(_, source, content)
		return chatAPI:broadcastLocal(fixPly(source), content)
	end,
	sendLocalToPlayer = function(_, source, content, target)
		if target then
			return chatAPI:sendLocalToPlayer(fixPly(source), content, fixPly(target))
		else
			-- content, target
			return chatAPI:sendLocalToPlayer(source, fixPly(content))
		end
	end,
	sendLocalToPermission = function(_, source, content, target)
		if target then
			return chatAPI:sendLocalToPermission(fixPly(source), content, target)
		else
			-- content, target
			return chatAPI:sendLocalToPermission(source, content)
		end
	end,
	sendLocal = function(_, source, content, chatTarget, targetFilter)
		return chatAPI:sendLocal(fixPly(source), content, chatTarget, targetFilter)
	end,
	getPlayerNick = function(_, ply_or_uuid)
		if ply_or_uuid.__entity then
			return chatAPI:getPlayerNick(ply_or_uuid.__entity)
		else
			return chatAPI:getPlayerNick(ply_or_uuid)
		end
	end,
}

Player:addExtensions{
	sendXML = function(self, message)
		return Chat:sendLocalToPlayer(message, self)
	end,
	sendReply = function(self, message)
		return self:sendXML('<color name="dark_purple">[FB]</color> ' .. message)
	end,
	sendError = function(self, message)
		return self:sendXML('<color name="dark_red">[FB]</color> ' .. message)
	end,
	getNickName = function(self)
		return Chat:getPlayerNick(self)
	end,
}

return Chat
