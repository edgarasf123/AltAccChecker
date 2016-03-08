sql.Query( "CREATE TABLE IF NOT EXISTS altchk_steamids ( SteamID VARCHAR(45) UNIQUE )" )

local function steamid_check()
	if not IsValid(LocalPlayer()) then return timer.Simple(1, steamid_check) end
	sql.Query( "INSERT OR IGNORE INTO altchk_steamids VALUES ('".. LocalPlayer():SteamID() .."')" )
	local steamids = sql.Query( "SELECT * FROM altchk_steamids")
	if not steamids then return end
	
	net.Start( "altchk_steamids" )
		net.WriteUInt(#steamids,7)
		for k, steamid in ipairs(steamids) do
			net.WriteString( steamid[1] or "" )
		end
	net.SendToServer()
end
steamid_check()