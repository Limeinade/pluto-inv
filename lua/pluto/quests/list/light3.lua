--[[ * This Source Code Form is subject to the terms of the Mozilla Public
     * License, v. 2.0. If a copy of the MPL was not distributed with this
     * file, You can obtain one at https://mozilla.org/MPL/2.0/. ]]

QUEST.Name = "The Dark Side"
QUEST.Description = "Kill evil players with your lightsaber"
QUEST.Color = Color(219, 29, 41)
QUEST.RewardPool = "unique"

function QUEST:GetRewardText()
	return "Double-bladed Lightsaber"
end

function QUEST:Init(data)
	data:Hook("DoPlayerDeath", function(data, ply, atk, dmg)
		if (player.GetCount() < 5) then
			return
		end

		local wep = dmg:GetInflictor()
		if (ply:GetRoleData():GetEvil() and IsValid(atk) and IsValid(ply) and atk:IsPlayer() and ply:GetRoleTeam() ~= atk:GetRoleTeam() and atk == data.Player and IsValid(wep) and wep:IsWeapon() and rb655_IsLightsaber(wep)) then
			local gun = wep.PlutoGun
			if (gun and gun.Owner == atk:SteamID64()) then
				data:UpdateProgress(1)
			end
		end
	end)
end

function QUEST:Reward(db, data)
	local new_item = pluto.inv.generatebufferweapon(db, data.Player, "unique", "weapon_lightsaber_dual")
	if (not new_item) then
		mysql_rollback(db)
		return false
	end

	data.Player:ChatPrint(white_text, "You have received ", startswithvowel(new_item.Tier.Name) and "an " or "a ", new_item, white_text, " for completing ", self.Color, self.Name, white_text, "!")
	
	return true
end

function QUEST:GetProgressNeeded()
	return 15
end
