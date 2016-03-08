util.AddNetworkString( "altchk_steamids" )
sql.Query( "CREATE TABLE IF NOT EXISTS altchk_players ( steamid VARCHAR(45) UNIQUE, ip VARCHAR(16) )" )

-- Change this to enable family sharing checking
local api_key = "" -- http://steamcommunity.com/dev/apikey

local function check_user( steamid_cur, steamid_alt )
	if steamid_cur == steamid_alt then return end
	
	local ban_data = ULib.bans[steamid_alt]
	-- In case original user gets unbanned, second condition will prevent him getting banned again for having alt. account (which is banned)
	if ban_data and string.sub( ban_data.reason or "", 1, 18 ) ~= "Altertnate Account" then
		ULib.addBan(steamid_cur, 0, "Altertnate Account of "..steamid_alt)
	end
end

net.Receive( "altchk_steamids", function( len, ply )
	if not ULib then error("AltChk: ULib not found!") return end
	local steamid = ply:SteamID()
	local steamids_num = net.ReadUInt(7)
	for i=1, steamids_num do
		local tmp_steamid = net.ReadString()
		check_user( steamid, tmp_steamid )
	end
end )


gameevent.Listen( "player_connect" )
hook.Add( "player_connect", "altchk_connect", function( data )
	if not ULib then error("AltChk: ULib not found!") return end
	local id = data.userid	
	local ip = data.address
	local steamid = data.networkid
	sql.Query( "INSERT OR REPLACE INTO altchk_players (steamid, ip) VALUES ('"..steamid.."', '"..ip.."')" );
	local steamids = sql.Query( "SELECT * FROM altchk_players WHERE ip='"..ip.."'") or {}
	for k, row in ipairs(steamids) do
		check_user( steamid, row.steamid )
	end
	
	if api_key ~= "" then
		http.Fetch(
			string.format("http://api.steampowered.com/IPlayerService/IsPlayingSharedGame/v0001/?key=%s&format=json&steamid=%s&appid_playing=4000",
				api_key,
				util.SteamIDTo64( steamid )
			),
			function(body)
				data = util.JSONToTable(body)
				local lender = data.response.lender_steamid
				if lender ~= "0" then
					check_user( steamid, util.SteamIDFrom64(lender) )
				end
			end,
			function(code)
				error("AltChk: Unable to reach SteamAPI server")
			end
		)
	end
end )