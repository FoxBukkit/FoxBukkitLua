/*
 * foxbukkit-lua-plugin - ${project.description}
 * Copyright © ${year} Doridian (git@doridian.net)
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
package net.doridian.foxbukkit.lua;

import net.doridian.foxbukkit.lua.compiler.LuaJC;
import org.bukkit.event.Listener;
import org.bukkit.plugin.Plugin;
import org.bukkit.scheduler.BukkitRunnable;
import org.luaj.vm2.Globals;
import org.luaj.vm2.LuaFunction;
import org.luaj.vm2.LuaValue;
import org.luaj.vm2.lib.jse.CoerceJavaToLua;
import org.luaj.vm2.lib.jse.JsePlatform;

import java.io.*;
import java.util.Scanner;
import java.util.logging.Level;

public class LuaState implements Listener, Runnable {
    final Object luaLock = new Object();
    Globals g;
    private volatile boolean running = true;
    private final String module;

    final FoxBukkitLua plugin;

    private final EnhancedChatMessageManager enhancedChatMessageManager;
    private final EnhancedPermissionManager enhancedPermissionManager;
    private final EventManager eventManager = new EventManager(this);
    private final CommandManager commandManager = new CommandManager(this);

    private static Plugin enhancedChatPlugin = null;
    private static Plugin enhancedPermissionPlugin = null;
    private static boolean loaded = false;

    public static synchronized void load(FoxBukkitLua plugin) {
        if(loaded) {
            return;
        }
        loaded = true;

        enhancedChatPlugin = plugin.getServer().getPluginManager().getPlugin("FoxBukkitChat");
        enhancedPermissionPlugin = plugin.getServer().getPluginManager().getPlugin("FoxBukkitPermissions");

        if(enhancedChatPlugin == null) {
            plugin.getLogger().log(Level.WARNING, "Could not find FoxBukkitChat. Disabling enhanced chat API.");
        } else {
            plugin.getLogger().log(Level.INFO, "Hooked FoxBukkitChat. Enabled enhanced chat API.");
        }

        if(enhancedPermissionPlugin == null) {
            plugin.getLogger().log(Level.WARNING, "Could not find FoxBukkitPermissions. Disabling enhanced permissions API.");
        } else {
            plugin.getLogger().log(Level.INFO, "Hooked FoxBukkitPermissions. Enabled enhanced permissions API.");
        }
    }

    public static synchronized void unload() {
        enhancedChatPlugin = null;
        enhancedPermissionPlugin = null;
        loaded = false;
    }

    public LuaState(String module, FoxBukkitLua plugin) {
        this.plugin = plugin;

        if(enhancedChatPlugin != null) {
            enhancedChatMessageManager = new EnhancedChatMessageManager(this, enhancedChatPlugin);
        } else {
            enhancedChatMessageManager = null;
        }

        if(enhancedPermissionPlugin != null) {
            enhancedPermissionManager = new EnhancedPermissionManager(this, enhancedPermissionPlugin);
        } else {
            enhancedPermissionManager = null;
        }

        this.module = module;
    }

    public String getModule() {
        return module;
    }

    public boolean isRunning() {
        return running;
    }

    public EventManager getEventManager() {
        return eventManager;
    }

    public EnhancedChatMessageManager getEnhancedChatMessageManager() {
        return enhancedChatMessageManager;
    }

    public EnhancedPermissionManager getEnhancedPermissionManager() {
        return enhancedPermissionManager;
    }

    public CommandManager getCommandManager() {
        return commandManager;
    }

    public Runnable createLuaValueRunnable(final LuaValue function) {
        return new BukkitRunnable() {
            @Override
            public void run() {
                synchronized (luaLock) {
                    function.call();
                }
            }
        };
    }

    public FoxBukkitLua getFoxBukkitLua() {
        return plugin;
    }

    public String readStream(InputStream stream) {
        try (Scanner scanner = new Scanner(stream)) {
            return scanner.useDelimiter("\\A").next();
        }
    }

    public String getRootDir() {
        try {
            return plugin.getLuaFolder().getCanonicalPath();
        } catch (IOException e) {
            return null;
        }
    }

    public String getModuleDir() {
        try {
            return new File(plugin.getLuaModulesFolder(), module).getCanonicalPath();
        } catch (IOException e) {
            return null;
        }
    }

    public LuaValue loadPackagedFile(String name) {
        synchronized (luaLock) {
            try {
                String className = "lua." + LuaJC.toStandardJavaClassName(name);
                LuaFunction value = (LuaFunction)Class.forName(className).newInstance();
                value.initupvalue1(g);
                return value;
            } catch (Exception e) {
                e.printStackTrace();
            }
            return null;
        }
    }

    private static boolean initialized = false;
    private synchronized void initialize() {
        if(initialized) {
            return;
        }
        initialized = true;

        File overrideBoot = new File(getRootDir(), "boot.lua");
        if(overrideBoot.exists()) {
            g.loadfile(overrideBoot.getAbsolutePath()).call();
        } else {
            loadPackagedFile("boot").call();
        }
    }

    public Class<?> bindClass(String clazz) throws ClassNotFoundException {
        return Class.forName(clazz);
    }

    @Override
    public void run() {
        synchronized (luaLock) {
            g = JsePlatform.standardGlobals();

            try {
                LuaJC.install(g, plugin.getDataFolder().getCanonicalPath());
            } catch (IOException e) {
                throw new RuntimeException(e);
            }

            initialize();

            g.set("__LUA_STATE", CoerceJavaToLua.coerce(this));
            File overrideInit = new File(getRootDir(), "init.lua");
            if(overrideInit.exists()) {
                g.loadfile(overrideInit.getAbsolutePath()).call();
            } else {
                loadPackagedFile("init").call();
            }
        }
    }

    public synchronized void terminate() {
        if(!running) {
            return;
        }
        running = false;

        synchronized (this) {
            synchronized (luaLock) {
                running = false;
                eventManager.unregisterAll();
                commandManager.unregisterAll();
            }
        }
    }
}
