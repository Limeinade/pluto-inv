--[[ * This Source Code Form is subject to the terms of the Mozilla Public
     * License, v. 2.0. If a copy of the MPL was not distributed with this
     * file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]
function pluto.inv.readgettrades(ply)
	local sid64 = net.ReadString()
	if (sid64 ~= ply:SteamID64() and not admin.hasperm(ply:GetUserGroup(), "tradelogs")) then
		return
	end
	pluto.db.instance(function(db)
		local logs = mysql_stmt_run(db, [[select tr.idx as trade_id, CAST(tr.snapshot AS CHAR(1000000)) as snapshot, p1.displayname as p1name, CAST(p1.steamid as CHAR(32)) as p1steamid, p2.displayname as p2name, cast(p2.steamid as CHAR(32)) as p2steamid
			from pluto_trades tr
			inner join pluto_trades_players search on tr.idx = search.trade_id
			inner join pluto_trades_players p2info on p2info.trade_id = tr.idx
			inner join pluto_player_info p2 on p2info.player = p2.steamid
			inner join pluto_player_info p1 on search.player = p1.steamid
				where version = 1 AND search.player = ?
				and p2info.player != search.player
				order by trade_id desc]],
			ply:SteamID64()
		)

		pluto.inv.message(ply)
			:write("tradelogresults", logs)
			:send()
	end)
end

function pluto.inv.readgettradesnapshot(cl)
	local trade_id = net.ReadUInt(32)
	local sid64 = pluto.db.steamid64(cl)

	pluto.db.instance(function(db)
		local logs
		if (admin.hasperm(cl:GetUserGroup(), "tradelogs")) then
			logs = mysql_stmt_run(db, [[select CAST(tr.snapshot AS CHAR(1000000)) as snapshot
				from pluto_trades tr 
					where tr.idx = ?
				]],
				trade_id
			)
		else
			logs = mysql_stmt_run(db, [[select CAST(tr.snapshot AS CHAR(1000000)) as snapshot
				from pluto_trades tr
				inner join pluto_trades_players search on tr.idx = search.trade_id and search.player = ?
					where tr.idx = ?
				]],
				sid64,
				trade_id
			)
		end
		if (not logs[1]) then
			cl:ChatPrint "You aren't allowed to access that."
			return
		end

		pluto.inv.message(cl)
			:write("tradelogsnapshot", trade_id, logs[1].snapshot)
			:send()
	end)
end

function pluto.inv.writetradelogresults(recv, trades)
	net.WriteUInt(#trades, 32)
	for _, trade in ipairs(trades) do
		net.WriteUInt(trade.trade_id, 32)
		net.WriteString(trade.p1name)
		net.WriteString(trade.p1steamid)
		net.WriteString(trade.p2name)
		net.WriteString(trade.p2steamid)
	end
end

function pluto.inv.writetradelogsnapshot(cl, id, snapshot)
	net.WriteUInt(id, 32)
	local comp = util.Compress(snapshot)
	net.WriteUInt(#comp, 32)
	net.WriteData(comp, #comp)
end

function pluto.inv.writetraderequestinfo(cl, oply)
	net.WriteEntity(oply)
	net.WriteString(pluto.trades.status(cl, oply))
end

function pluto.inv.writetradeupdate(ply, who, what, index, data)
	net.WriteBool(who ~= ply)
	net.WriteString(what)
	net.WriteUInt(index, 8)
	if (not data) then
		net.WriteBool(false)
	else
		net.WriteBool(true)
		if (what == "currency") then
			net.WriteString(data.What)
			net.WriteUInt(data.Amount, 32)
		elseif (what == "item") then
			pluto.inv.writeitem(ply, data)
		end
	end
end


function pluto.inv.readtrademessage(cl)
	local msg = net.ReadString()

	local active = pluto.trades.active[cl]
	if (active) then
		active.data:AddPlayerMessage(cl, msg)
	end
end

function pluto.inv.writetrademessage(_, msg, cl)
	if (cl) then
		net.WriteBool(true)
		net.WriteEntity(cl)
	else
		net.WriteBool(false)
	end

	net.WriteString(msg)
end

function pluto.inv.writetradestatus(_, cl, status)
	net.WriteEntity(cl)
	net.WriteBool(status)
end