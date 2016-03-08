if SERVER then
	AddCSLuaFile("altchk/client.lua")
	include("altchk/server.lua")
else
	include("altchk/client.lua")
end