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
string.contains = function(self, sub)
	return self:find(sub, 1, true) ~= nil
end

string.containsAnyOf = function(self, chars)
	return self:find('[' .. chars .. ']') ~= nil
end

string.containsNoneOf = function(self, chars)
	return not self:containsAnyOf(chars)
end

string.stripColors = function(self)
	return self:gsub('\xC2\xA7.', '')
end

string.ucfirst = function(self)
	if self:len() < 2 then
		return self:upper()
	end
	return self:sub(1, 1):upper() .. self:sub(2):lower()
end

table.contains = function(tbl, value)
	for _, v in next, tbl do
		if v == value then
			return true
		end
	end
	return false
end
