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

local luaState = __LUA_STATE
local dofile = dofile

rawset(_G, 'dofile', nil)
rawset(_G, 'loadfile', nil)
rawset(_G, 'dostring', nil)
rawset(_G, 'loadstring', nil)
rawset(os, 'execute', nil)

local boundClasses = {}
local classBounds = {}

function bindClass(cls)
	local clsB = boundClasses[cls]
	if not clsB then
		clsB = luaState:bindClass(cls)
		boundClasses[cls] = clsB
		classBounds[clsB] = cls
	end
	return clsB
end

function getClassName(cls)
	local name = classBounds[cls]
	if not name then
		name = tostring(cls):sub(7)
		bindClass(name)
	end
	return name
end

local includeDir = luaState:getModuleDir()
local File = bindClass('java.io.File')

package.path = includeDir .. '/classes/?.lua;' .. luaState:getRootDir() .. '/classes/?.lua'

table.insert(package.searchers, 3, function(module)
	return luaState:loadPackagedFile('classes/' .. module)
end)

local function _scandir(dir, cb, recursive, ignore, rootDirLen)
	local iter = dir:listFiles()
	for i = 1, #iter do
		local v = iter[i]
		if not ignore[v:getName()] then
			if recursive and v:isDirectory() then
				_scandir(v, cb, recursive, {}, rootDirLen)
			else
				cb(v:getAbsolutePath():sub(rootDirLen))
			end
		end
	end
end
local function scandir(dir, cb, recursive, ignore)
	local ignoreTbl = {}
	if type(ignore) == 'table' then
		for _, v in next, ignore do
			ignoreTbl[v] = true
		end
	elseif ignore then
		ignoreTbl[ignore] = true
	end
	if type(dir) == 'string' then
		dir = luajava.new(File, includeDir .. '/' .. dir)
	end
	_scandir(dir, cb, recursive, ignoreTbl, dir:getAbsolutePath():len() + 2)
end

scandir(
	'',
	function(file)
		dofile(includeDir .. '/' .. file)
	end,
	true,
	{ 'classes', 'storage' }
)
