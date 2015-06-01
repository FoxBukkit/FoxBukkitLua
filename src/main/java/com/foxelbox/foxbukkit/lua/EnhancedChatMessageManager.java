/**
 * This file is part of FoxBukkitLua.
 *
 * FoxBukkitLua is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * FoxBukkitLua is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with FoxBukkitLua.  If not, see <http://www.gnu.org/licenses/>.
 */
package com.foxelbox.foxbukkit.lua;

import com.foxelbox.foxbukkit.chatcomponent.FBChatComponent;
import com.foxelbox.foxbukkit.chatcomponent.RedisHandler;
import com.foxelbox.foxbukkit.chatcomponent.json.ChatMessageIn;
import com.foxelbox.foxbukkit.chatcomponent.json.ChatMessageOut;
import com.foxelbox.foxbukkit.chatcomponent.json.MessageTarget;
import com.foxelbox.foxbukkit.chatcomponent.json.UserInfo;
import org.bukkit.command.CommandSender;
import org.bukkit.plugin.Plugin;

import java.util.UUID;

public class EnhancedChatMessageManager {
    private final RedisHandler redisHandler;
    private final FBChatComponent fbChatComponent;
    private final LuaThread luaThread;

    public EnhancedChatMessageManager(LuaThread luaThread, Plugin enhancedChatPlugin) {
        try {
            fbChatComponent = (FBChatComponent) enhancedChatPlugin;
            redisHandler = fbChatComponent.getRedisHandler();
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
        this.luaThread = luaThread;
    }

    private CommandSender getConsole() {
        return FoxBukkitLua.instance.getServer().getConsoleSender();
    }

    public void sendGlobal(CommandSender source, String type, String content) {
        ChatMessageIn chatMessageIn = new ChatMessageIn(source);
        chatMessageIn.contents = content;
        chatMessageIn.type = type;
        RedisHandler.sendMessage(chatMessageIn);
    }

    public void broadcastLocal(CommandSender source, String content) {
        sendLocal(source, content, "all", null);
    }

    public void sendLocalToPlayer(CommandSender source, String content, CommandSender target) {
        sendLocal(source, content, "player", new String[] { Utils.getCommandSenderUUID(target).toString() });
    }

    public void sendLocalToPermission(CommandSender source, String content, String target) {
        sendLocal(source, content, "permission", new String[] { target });
    }

    public void broadcastLocal(String content) {
        broadcastLocal(getConsole(), content);
    }

    public void sendLocalToPlayer(String content, CommandSender target) {
        sendLocalToPlayer(getConsole(), content, target);
    }

    public void sendLocalToPermission(String content, String target) {
        sendLocalToPermission(getConsole(), content, target);
    }

    public void sendLocal(CommandSender source, String content, String chatTarget, String[] targetFilter) {
        ChatMessageOut chatMessageOut = new ChatMessageOut();
        chatMessageOut.server = null;
        chatMessageOut.from = new UserInfo(Utils.getCommandSenderUUID(source), source.getName());
        chatMessageOut.context = UUID.randomUUID();
        chatMessageOut.finalize_context = true;
        chatMessageOut.contents = content;
        chatMessageOut.to = new MessageTarget(chatTarget, targetFilter);
        redisHandler.onMessage(chatMessageOut);
    }
}