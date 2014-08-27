--[[
NotLib version 9
by Ivan[RUSSIA]

GPL v2 license
--]]

-- INIT
NotLib = {}
-- MATH
NotLib.math = function()
	NotLib.math = function() end
	
	VEC = function(x,z) return D3DXVECTOR3(x,0,z) end

	math.dist2d = function(x1,y1,x2,y2)
		return math.sqrt((x2 - x1)^2 + (y2 - y1)^2)
	end

	math.rad2d = function(pos1,pos2)
		if pos2.z > pos1.z then
			if pos1.x < pos2.x then return math.acos(math.dist2d(pos1.x,pos1.z,pos1.x,pos2.z)/(pos1:GetDistance(pos2)))
			else return 6.283185307 - math.acos(math.dist2d(pos1.x,pos1.z,pos1.x,pos2.z)/(pos1:GetDistance(pos2))) end
		else 
			if pos1.x < pos2.x then return 1.570796327 + math.acos(math.dist2d(pos1.x,pos2.z,pos2.x,pos2.z)/(pos1:GetDistance(pos2)))
			else return 4.712388980 - math.acos(math.dist2d(pos1.x,pos2.z,pos2.x,pos2.z)/(pos1:GetDistance(pos2))) end
		end
	end

	math.pos2d = function(pos,rad,range)
		return VEC(pos.x + math.sin(rad) * range,pos.z + math.cos(rad) * range)
	end

	math.normal2d = function(pos1,pos2)
		local rad = math.rad2d(pos1,pos2)
		return VEC(math.sin(rad),math.cos(rad))
	end

	math.proj2d = function(dotPos,linePos1,linePos2)
		dotPos = VEC(dotPos.x,dotPos.z)
		local dotRad = math.rad2d(linePos1,dotPos)
		local lineRad = math.rad2d(linePos1,linePos2)
		return math.pos2d(linePos1,lineRad,math.cos(lineRad - dotRad) *  dotPos:GetDistance(linePos1))
	end

	math.center2d = function()
		return D3DXVECTOR3(cameraPos.x,-161.1643,cameraPos.z + (cameraPos.y + 161.1643) * math.sin(0.6545))
	end
end
-- TIMER
NotLib.timer = function()
	NotLib.timer = function() end
	
	local timerCache = {}
	AddTickCallback(function()
			local clock = GetTickCount() / 1000
			for key,handle in pairs(timerCache) do if handle.lastcall + handle.cooldown <= clock then
					handle.lastcall = handle.lastcall + handle.cooldown
					handle.callback()
			end end
		end)
	timer = function(key)
		if timerCache[key] == nil then
			timerCache[key] = {lastcall = math.huge,cooldown = 0,callback = function() end}
			timerCache[key].callback = function() end
			timerCache[key].stop = function() timerCache[key].lastcall = math.huge end
			timerCache[key].pause = function(timeline) timerCache[key].lastcall = timerCache[key].lastcall + timeline end
			timerCache[key].start = function(callback) 
				timerCache[key].lastcall = GetTickCount()/1000 
				if callback == true then timerCache[key].callback() end
			end
			timerCache[key].disable = function() timerCache[key] = nil end
		end
		return timerCache[key]
	end
end
-- BIND
NotLib.bind = function()
	NotLib.bind = function() end
	
	local bindCache = {}
	AddMsgCallback(function(msg,wParam)
			if msg == 0x200 then wParam,msg = 0x0,KEY_DOWN elseif msg == 0x202 then wParam,msg = 0x1,KEY_UP 
			elseif msg == 0x205 then wParam,msg = 0x2,KEY_UP elseif msg == 0x208 then wParam,msg = 0x4,KEY_UP end
			for key,handle in pairs(bindCache) do if handle.key == wParam then handle.callback(msg ~= KEY_UP) if bindCache[key] == nil then return end end end
		end)
	bind = function(key)
		if bindCache[key] == nil then
			bindCache[key] = {key = math.huge}
			bindCache[key].callback = function() end
			bindCache[key].disable = function() bindCache[key] = nil end
		end
		return bindCache[key]
	end
end
-- GUI
NotLib.gui = function()
	NotLib.gui = function() end
	
	NotLib.bind() -- required for moveable elements
	NotLib.math() -- required for WorldToScreen
	
	local font,back = 0xAAFFFF00,0xBB964B00 
	local tSize,lSize = math.max(5,WINDOW_H/40),math.max(1,WINDOW_H/225)
	local lSize2,lSize3,lSize4 = lSize*2,lSize*3,lSize*4
	--local map = {x = 0.7085 + WINDOW_W/WINDOW_H * 0.1, y = 0.79}]]
	
	local guiCache = {}
	AddDrawCallback(function() for k,handle in pairs(guiCache) do if handle.visible == true then handle.callback() end end end)
	gui = function(key)
		if guiCache[key] == nil then 
			local handle = {x=0,y=0,visible=true,children = {},parent = nil}
			handle.inside = function(pos) 
				return pos.x >= handle.x and pos.x <= handle.x + handle.w and pos.y >= handle.y and pos.y <= handle.y + handle.h 
			end
			handle.reset = function()
				handle.w,handle.h,handle.min,handle.max,handle.text,handle.value = 0,0,0,0,"text",nil
				handle.callback = function() end
				handle.changed = function() end
				handle.refresh = function() end
				-- disable binds
				bind(key).disable()
				bind(key.."moving").disable()
			end
			handle.disable = function()
				-- make parent forget about you
				if handle.parent ~= nil then for k,v in pairs(guiCache[handle.parent].children) do if v == key then table.remove(guiCache[handle.parent].children,k) gui(handle.parent).refresh() end end end
				-- make children forget about you THEN kill children
				for k,v in pairs(handle.children) do gui(v).parent = nil gui(v).disable() 
				end
				-- forget yourself
				guiCache[key] = nil
				-- disable binds
				bind(key).disable()
				bind(key.."moving").disable()
			end
			handle.transform = function(to,...)
				local handle = guiCache[key]
				-- reset
				handle.reset()
				-- add children
				handle.children = {...}
				for i=1,#handle.children do gui(handle.children[i]).parent = key end
				-- start transforming
				if to == "text" then
					handle.refresh = function()
						handle.w,handle.h = GetTextArea(handle.text,tSize).x,tSize
					end
					handle.callback = function()
						DrawText(handle.text,tSize,handle.x,handle.y,font) 
					end
				elseif to == "button" then
					handle.refresh = function()
						handle.w,handle.h = GetTextArea(handle.text,tSize).x+tSize,tSize
					end
					handle.callback = function() 
						DrawLine(handle.x,handle.y+tSize/2,handle.x+handle.w,handle.y+tSize/2,handle.h,back)
						DrawText(handle.text,tSize,handle.x+tSize/2,handle.y,font)
					end
					bind(key).key = 0x1
					bind(key).callback = function(down) if handle.visible == true and handle.inside(GetCursorPos()) == true then 
						handle.changed(down)
					end end
				elseif to == "tick" then
					handle.value = false
					handle.w,handle.h = tSize,tSize
					handle.callback = function() 
						DrawLine(handle.x,handle.y,handle.x+tSize,handle.y,lSize,back)
						DrawLine(handle.x,handle.y,handle.x,handle.y+tSize,lSize,back)
						DrawLine(handle.x,handle.y+tSize,handle.x+tSize,handle.y+tSize,lSize,back)
						DrawLine(handle.x+tSize,handle.y,handle.x+tSize,handle.y+tSize,lSize,back)
						if handle.value == true then
							DrawLine(handle.x+tSize/6,handle.y+tSize/2.3,handle.x+tSize/2,handle.y+tSize/1.3,lSize,font)
							DrawLine(handle.x+tSize/2,handle.y+tSize/1.3,handle.x+tSize/1.3,handle.y+tSize/7,lSize,font)
						end
					end
					bind(key).key = 0x1
					bind(key).callback = function(down) if down and handle.visible == true and handle.inside(GetCursorPos()) == true then
						handle.value = not handle.value
					end end
				elseif to == "bar" then
					handle.value = 0
					handle.refresh = function()
						handle.w,handle.h = tSize*5.5+math.max(GetTextArea(tostring(handle.min),tSize).x,GetTextArea(tostring(handle.max),tSize).x),tSize
					end
					handle.callback = function()
						DrawLine(handle.x,handle.y+tSize/2,handle.x+tSize*5,handle.y+tSize/2,tSize,back)
						local valueX = handle.x+(tSize*5)/(handle.max-handle.min)*(handle.value-handle.min)
						DrawLine(handle.x,handle.y+tSize/2,valueX,handle.y+tSize/2,tSize,font)
						DrawText(tostring(handle.value),tSize,handle.x+tSize*5.25,handle.y,font)
					end
				elseif to == "slider" then
					handle.value = 0
					handle.refresh = function()
						handle.w,handle.h = tSize*5.5+lSize+math.max(GetTextArea(tostring(handle.min),tSize).x,GetTextArea(tostring(handle.max),tSize).x),tSize
					end
					handle.callback = function()
						DrawLine(handle.x,handle.y+tSize/2,handle.x+tSize*5,handle.y+tSize/2,lSize,back)
						local valueX = handle.x+(tSize*5)/(handle.max-handle.min)*(handle.value-handle.min)
						DrawLine(valueX,handle.y,valueX,handle.y+tSize,lSize2,font)
						DrawText(tostring(handle.value),tSize,handle.x+tSize*5.25+lSize,handle.y,font)
					end
					bind(key).key = 0x1
						bind(key).callback = function(down)
						if down == true and handle.visible == true and handle.inside(GetCursorPos()) then
							bind(key.."moving").key = 0x0
							bind(key.."moving").callback = function()
								handle.value = math.min(handle.max,math.max(handle.min,math.floor(handle.min+(GetCursorPos().x-handle.x)*(handle.max-handle.min)/(tSize*5)+0.5)))
							end
							bind(key.."moving").callback()
						elseif down == false then bind(key.."moving").disable() end
					end
				elseif to == "line" then
					handle.refresh = function()
						local w,h = 0,0
						for i=1,#handle.children do if gui(handle.children[i]).visible == true then
							gui(handle.children[i]).x,gui(handle.children[i]).y = handle.x+w,handle.y
							w,h = w+gui(handle.children[i]).w+lSize2,math.max(h,gui(handle.children[i]).h)
						end end
						handle.w,handle.h = math.max(0,w-lSize2),h
					end
				elseif to == "list" then
					handle.refresh = function()
						local h,w = 0,0
						for i=1,#handle.children do if gui(handle.children[i]).visible == true then
							gui(handle.children[i]).y,gui(handle.children[i]).x = handle.y+h,handle.x
							h,w = h+gui(handle.children[i]).h+lSize2,math.max(w,gui(handle.children[i]).w)
						end end
						handle.h,handle.w = math.max(0,h-lSize2),w
					end
				elseif to == "anchor" then
					handle.refresh = function()
						local h,w = 0,lSize4
						for i=1,#handle.children do if gui(handle.children[i]).visible == true then
							gui(handle.children[i]).y,gui(handle.children[i]).x = handle.y+h,handle.x+w
							h,w = h+gui(handle.children[i]).h+lSize2,math.max(w,gui(handle.children[i]).w)
						end end
						handle.h,handle.w = math.max(lSize4,h-lSize2),w
					end
					handle.callback = function()
						DrawLine(handle.x+lSize,handle.y,handle.x+lSize,handle.y+handle.h,lSize2,font)
					end
					bind(key).key = 0x1
					bind(key).callback = function(down)
						if down == true and handle.visible == true and GetCursorPos().x >= handle.x and GetCursorPos().x <= handle.x+lSize2 
						and GetCursorPos().y >= handle.y and GetCursorPos().y <= handle.y+handle.h then
							local anchor = {x = GetCursorPos().x-handle.x,y = GetCursorPos().y-handle.y}
							bind(key.."moving").key = 0x0
							bind(key.."moving").callback = function() 
								handle.x = math.min(WINDOW_W-handle.w,math.max(0,GetCursorPos().x-anchor.x))
								handle.y = math.min(WINDOW_H-handle.h,math.max(0,GetCursorPos().y-anchor.y))
							end
						elseif down == false then bind(key.."moving").disable() end
					end
				elseif to == "world" then
					handle.value = VEC(0,0)
					handle.callback = function()
						local pos = WorldToScreen(handle.value)
						gui(handle.children[1]).x,gui(handle.children[1]).y = pos.x,pos.y
					end
				elseif to == "question" then
					gui(key.."qtext").transform("text")
					gui(key.."qbutton1").transform("button").text = "yes"
					gui(key.."qbutton1").changed = function(down) if down == false then handle.disable() handle.changed(true) end end
					gui(key.."qbutton2").transform("button").text = "no"
					gui(key.."qbutton2").changed = function(down) if down == false then handle.disable() handle.changed(false) end end
					gui(key.."qline").transform("line",key.."qbutton1",key.."qbutton2")
					handle.transform("list",key.."qtext",key.."qline")
					handle.refresh = function() if gui(key.."qtext").text ~= handle.text then gui(key.."qtext").text = handle.text end end
				elseif to == "test" then
					gui(key.."testtext").transform("text").text = "NotLib.gui test"
					gui(key.."testbar").transform("bar")
					gui(key.."testbar").value,gui(key.."testbar").min,gui(key.."testbar").max = 15,10,20
					gui(key.."testslider").transform("slider").changed = function(value) gui(key.."testbar").value = value end
					gui(key.."testslider").value,gui(key.."testslider").min,gui(key.."testslider").max = 15,10,20
					gui(key.."testbutton").transform("button").changed = function(state) gui(key.."testslider").value = 15 end
					gui(key.."testbutton").text = "reset"
					gui(key.."testline").transform("line",key.."testbar",key.."testslider",key.."testbutton")
					gui(key.."testquestion").transform("question").changed = function(state) if state then handle.disable() end end
					gui(key.."testquestion").text = "Shut down test?"
					gui(key.."testlist").transform("list",key.."testtext",key.."testline",key.."testquestion")
					gui(key.."anchor").transform("anchor",key.."testlist")
					handle.transform("world",key.."anchor").value = myHero
				end
				handle.refresh()
				if handle.parent ~= nil then gui(handle.parent).refresh() end
				return handle
			end
			handle.reset()
			guiCache[key] = setmetatable({},{__index = function(t,k) return handle[k] end,__newindex = function(t,k,v) if handle[k] ~= v then 
					handle[k] = v
					if k == "x" or k == "y" then handle.refresh()
					elseif (k == "w" or k == "h") and handle.parent ~= nil then gui(handle.parent).refresh()
					elseif (k == "text" or k == "min" or k == "max") then handle.refresh()
					elseif k == "value" then handle.changed(handle.value)
					elseif k == "visible" then
						for i=1,#handle.children do gui(handle.children[i]).visible = handle.visible end
						handle.refresh()
					end
				end end})
		end
		return guiCache[key]
	end
end
-- SPELL CLASSIFICATION
NotLib.spell = function()
	NotLib.spell,spell = function() end,{}
	
	NotLib.timer() -- required for spell.OnGainBuff callback
	NotLib.math() -- required for warding
	NotLib.object() -- required for warding
	
	for i=0,1,1 do
		local name = GetSpellData(SUMMONER_1+i).name
		if name == "SummonerSmite" then spell.smite = SUMMONER_1+i
		elseif name == "SummonerHaste" then spell.ghost = SUMMONER_1+i
		elseif name == "SummonerRevive" then spell.revive = SUMMONER_1+i
		elseif name == "SummonerHeal" then spell.heal = SUMMONER_1+i
		elseif name == "SummonerTeleport" then spell.teleport = SUMMONER_1+i
		elseif name == "SummonerFlash" then spell.flash = SUMMONER_1+i
		elseif name == "SummonerDot" then spell.ignite = SUMMONER_1+i
		elseif name == "SummonerBarrier" then spell.barrier = SUMMONER_1+i
		elseif name == "SummonerExhaust" then spell.exhaust = SUMMONER_1+i
		elseif name == "SummonerBoost" then spell.cleanse = SUMMONER_1+i
		elseif name == "SummonerMana" then spell.clarity = SUMMONER_1+i end
	end

	spell.level = function(list)
		local lev,req = {},{}
		lev[_Q],lev[_W],lev[_E],lev[_R] = GetSpellData(_Q).level,GetSpellData(_W).level,GetSpellData(_E).level,GetSpellData(_R).level
		if myHero.charName == "Elise" or myHero.charName == "Karma" or myHero.charName == "Jayce" then lev[_R] = lev[_R] - 1 end
		for i=1,#list do
			req[list[i]] = (req[list[i]] or 0) + 1
			if req[list[i]] > lev[list[i]] then LevelSpell(list[i]) return end
		end
	end

	spell.item = function(unit,id,usable)
		if type(unit) ~= "userdata" then 
			usable = id
			id = unit
			unit = myHero
		end
		for i=ITEM_1,ITEM_7,1 do
			if myHero:getInventorySlot(i) == id and (usable ~= true or myHero:CanUseSpell(i) == READY) then return i end
		end
	end
	
	spell.buff = function(unit,...)
		local list = {...}
		if type(unit) ~= "userdata" then 
			list[#list+1] = unit 
			unit = myHero
		end
		for i=0,unit.buffCount do
			local buff = unit:getBuff(i)
			if buff.valid then for h=1,#list,1 do if buff.name == list[h] then return true end end end
		end
		return false
	end
	
	spell.ward = function(wards)
		local slot = spell.item(3340,true) or spell.item(3361,true) or spell.item(2049,true) or spell.item(2045,true) or spell.item(3154,true) or spell.item(2044,true)
		if slot ~= nil then
			local pos = object.filter(wards,{closest=true,range=500})
			if pos ~= nil and #object.filter(object.ward,{range=1600,dead=false,unit=pos,visible=true,team=myHero.team}) == 0 then 
				CastSpell(slot,pos.x+math.random(-0.5,0.5),pos.z+math.random(-0.5,0.5)) 
				return true
			end
		end
		return false
	end
	-- buys item
	local _buy = {}
	spell.buy = function(id)
		if GetTickCount()/1000-(_buy[id] or 0) > GetLatency()/200 then
			_buy[id] = GetTickCount()/1000
			BuyItem(id)
		end
	end
	-- return usefull shopping routine
	spell.itemList = function(list)
		list = list or {}
		
		list.refresh = function()
			local i=1
			while i <= #list do
				local bought = spell.item(list[i][1])
				for x=3,#list[i],1 do bought = bought or spell.item(list[i][x]) end
				if bought then table.remove(list,i) else i = i + 1 end
			end
		end
		
		list.buy = function()
			list.refresh()
			if list[1] ~= nil and myHero.gold >= list[1][2] then spell.buy(list[1][1]) end
		end
		
		list.gold = function()
			list.refresh()
			if #list == 0 then return 0
			else
				local price = 0
				for i=1,#list do price = price + list[i][2] end
				return price
			end
		end
		
		list.add = function(newList)
			for i=1,#newList do list[#list+1] = newList[i] end
		end
		
		return list
	end

	spell.OnGainBuff = function(callback)
		assert(AddRecvPacketCallback,"NotLib.lua >> spell.OnGainBuff() >> VIP check fail")
		AddRecvPacketCallback(function(p) if p.header == 183 then
				p.pos = 1
				local unit = objManager:GetObjectByNetworkId(p:DecodeF())
				if unit ~= nil then 
					local buff = {}
					p.pos = 5
					buff.slot = p:Decode1()+1
					p.pos = 6
					buff.type = p:Decode1()
					p.pos = 7
					buff.visible = (p:Decode1() == 1)
					p.pos = 8
					buff.stack = p:Decode1()
					p.pos = 25
					buff.source = objManager:GetObjectByNetworkId(p:DecodeF())
					timer("OnGainBuff"..tostring(buff.slot)).callback = function()
						timer("OnGainBuff"..tostring(buff.slot)).disable()
						buff.name = myHero:getBuff(buff.slot).name
						buff.startT = myHero:getBuff(buff.slot).startT or -math.huge
						buff.endT = myHero:getBuff(buff.slot).endT or math.huge
						buff.duration = buff.endT - buff.startT
						callback(unit,buff)
					end
					timer("OnGainBuff"..tostring(buff.slot)).start()
				end
			end end)
	end
	spell.move = function(x,z) if type(x) == "number" then myHero:MoveTo(x+math.random(-10,10),z+math.random(-10,10)) else myHero:MoveTo(x.x+math.random(-10,10),x.z+math.random(-10,10)) end end
	spell.range = function(target) return myHero:GetDistance(myHero.minBBox)+target:GetDistance(target.minBBox)+50 end
	spell.follow = function(target) if myHero:GetDistance(target) > target:GetDistance(target.minBBox)+50 then spell.move(target.x,target.z) end end
end
-- OBJECT CLASSIFICATION
NotLib.object = function()
	NotLib.object = function() end
	object = {shrine={},useless={},visual={},minion={},ward={},creep={},point={},event={},trap={},pet={},tower={},player={},shop={},nexus={},inhibitor={},spawn={},minionSpawn={},creepSpawn={},spell={},error={}}
	
	NotLib.math() -- required for lane detection
	
	-- look for spawn
	for i=1,objManager.maxObjects do
		local unit = objManager:getObject(i)
		if unit ~= nil and unit.valid == true and unit.type == "obj_SpawnPoint" then 
			if unit.team == myHero.team then object.allySpawn = unit
			elseif unit.team == TEAM_ENEMY then object.enemySpawn = unit end
		end
	end
	assert(object.allySpawn and object.enemySpawn,"NotLib.lua >> NotLib.object() >> objManager fail")
	-- look for map
	object.map = object.allySpawn:GetDistance(object.enemySpawn)
	if object.map < 12810 then object.map="dom" elseif object.map < 13270 then object.map="tt" 
	elseif object.map < 15185 then object.map="pg" elseif object.map < 19680 then object.map="classic" else object.map="unknown" end
	assert(object.map ~= "unknown","NotLib.lua >> NotLib.object() >> object.map fail")
	-- definition
	object.class = function(unit)
		local type = unit.type
		if type ==  "obj_Turret" or type == "obj_Levelsizer" or type == "obj_NavPoint" or type ==  "LevelPropSpawnerPoint" 
		or type ==  "LevelPropGameObject" or type == "GrassObject" or type ==  "obj_Lake" or type ==  "obj_LampBulb" or type ==  "DrawFX" then return "useless"
		elseif type ==  "obj_GeneralParticleEmitter" or type == "obj_AI_Marker" or type == "FollowerObject" then return "visual"
		elseif type ==  "obj_AI_Minion" then
			local name = unit.name:lower()
			if name:find("minion") then return "minion"
			elseif name:find("ward") then return "ward"
			elseif (name:find("wolf") or name:find("wraith") or name:find("golem") or name:find("lizard") or name:find("dragon") or name:find("worm") or name:find("spider")) and unit.name:find("%d+%.%d+") then return "creep"
			elseif name:find("buffplat") or name == "odinneutralguardian" then return "point"
			elseif name:find("shrine") or name:find("relic") then return "event"
			elseif unit.bTargetableToTeam == false or unit.bTargetable == false then return "trap" 
			else return "pet" end
		elseif type ==  "obj_AI_Turret" then return "tower"
		elseif type == "AIHeroClient" then return "player"
		elseif type ==  "obj_Shop" then return "shop"
		elseif type ==  "obj_HQ" then return "nexus"
		elseif type ==  "obj_BarracksDampener" then return "inhibitor"
		elseif type ==  "obj_SpawnPoint" then return "spawn"
		elseif type ==  "obj_Barracks" then return "minionSpawn"
		elseif type ==  "NeutralMinionCamp" then return "creepSpawn"
		elseif type ==  "obj_InfoPoint" then return "event"
		elseif type == "SpellMissileClient" or type == "SpellCircleMissileClient" or type == "SpellLineMissileClient" or type == "SpellChainMissileClient" then return "spell" end
		return "error"
	end
	-- collection
	object.add = function(unit)
		if type(unit.data) ~= "table" then unit.data = {} end
		unit.data.class = object.class(unit)
		if object[unit.data.class] == nil then print(unit.data.class) end
		object[unit.data.class][unit.hash] = unit
	end
	AddCreateObjCallback(object.add)
	object.remove = function(unit)
		if type(unit.data) == "table" then object[unit.data.class][unit.hash] = nil end
	end
	AddDeleteObjCallback(object.remove)
	for i=1,objManager.maxObjects do
		local unit = objManager:getObject(i)
		if unit ~= nil and unit.valid == true then object.add(unit) end
	end
	-- combine
	object.combine = function(units)
		local result = {}
		for key in units:gmatch("%w+") do for k,unit in pairs(object[key]) do result[#result+1] = unit end end
		return result
	end
	-- map position
	local mid = {classic = {VEC(1360,1630),VEC(12570,12810)},tt = VEC(7700,6700),dom = VEC(6900,6460)}
	object.mid = function(units,state)
		if state == nil then state = true end
		local result = {}
		for k,v in pairs(units,state) do
			if ((object.map == "classic" and v:GetDistance(math.proj2d(v,mid.classic[1],mid.classic[2])) <= 850)
			or (object.map == "tt" and v:GetDistance(mid.tt) <= 1100)
			or (object.map == "dom" and v:GetDistance(mid.dom) <= 1100)
			or object.map == "pg") == state then result[#result+1] = v end
		end
		return result
	end
	local top = {classic = {VEC(2000,12500),VEC(1000,1700),VEC(1000,11500),VEC(12500,13250),VEC(3400,13250)},tt = {VEC(2121,9000),VEC(13285,9000)}}
	object.top = function(units,state)
		if state == nil then state = true end
		local result = {}
		for k,v in pairs(units) do
			if ((object.map == "classic" and (v:GetDistance(top.classic[1]) <= 1100 or v:GetDistance(math.proj2d(v,top.classic[2],top.classic[3])) <= 850 
			or v:GetDistance(math.proj2d(v,top.classic[4],top.classic[5])) <= 850))
			or (object.map == "tt" and v:GetDistance(math.proj2d(v,top.tt[1],top.tt[2])) <= 1300)) == state then result[#result+1] = v end
		end
		return result
	end
	local bot = {classic = {VEC(12100,2175),VEC(1330,1150),VEC(12000,1150),VEC(13100,12850),VEC(13100,3000)},tt = {VEC(2121,5600),VEC(13285,5600)}}
	object.bot = function(units,state)
		if state == nil then state = true end
		local result = {}
		for k,v in pairs(units) do
			if ((object.map == "classic" and (v:GetDistance(bot.classic[1]) <= 1100 or v:GetDistance(math.proj2d(v,bot.classic[2],bot.classic[3])) <= 850 
			or v:GetDistance(math.proj2d(v,bot.classic[4],bot.classic[5])) <= 850))
			or (object.map == "tt" and v:GetDistance(math.proj2d(v,bot.tt[1],bot.tt[2])) <= 950)) == state then result[#result+1] = v end
		end
		return result
	end
	-- filter
	object.filter = function(units,param)
		if type(units) == "string" then units = object.combine(units) end
		param.unit = param.unit or myHero
		if param.mid ~= nil then units = object.mid(units,param.mid) end
		if param.top ~= nil then units = object.top(units,param.top) end
		if param.bot ~= nil then units = object.bot(units,param.bot) end
		local result = {}
		for k,unit in pairs(units) do
			if  (param.visible == nil or unit.visible == param.visible) and (param.targetable == nil or unit.bTargetable == param.targetable) 
			and (param.team == nil or unit.team == param.team) and (param.dead == nil or unit.dead == param.dead)  
			and (param.range == nil or (unit.name and unit:GetDistance(param.unit) <= param.range) or (param.unit.name and param.unit:GetDistance(unit) < param.range))
			and (param.name == nil or unit.name:lower():find(param.name:lower()))   then result[#result+1] = unit end
		end
		if param.closest == true then
			local closest = nil
			for i=1,#result do if closest == nil or param.unit:GetDistance(result[i]) < param.unit:GetDistance(closest) then closest = result[i] end end
			return closest
		end
		return result
	end
end
-- OBJECT UPGRADE
NotLib.upgrade = function()
	NotLib.upgrade,upgrade = function() end,{}
	
	NotLib.object() -- required
	NotLib.timer() -- required for miss
	
	local _creep = function(creep)
		creep.data.number = tonumber(creep.name:sub(creep.name:find("%d+"),creep.name:find("%.")-1))
		creep.data.parent = function() for k,creepSpawn in pairs(object.creepSpawn) do if creepSpawn.data.number == creep.data.number then return creepSpawn end end end
	end
	upgrade.creep = function()
		upgrade.creep = function() end
		
		upgrade.creepSpawn()
		for k,creep in pairs(object.creep) do _creep(creep) end
		AddCreateObjCallback(function(unit) if unit.data.class == "creep" then _creep(unit) end end)
	end
	
	local _creepSpawn = function(unit)
		unit.data.number = tonumber(unit.name:sub(unit.name:find("%d+")))
		unit.data.children = function()
			local result = {}
			for k,creep in pairs(object.creep) do if unit.data.number == creep.data.number then result[#result+1] = creep end end
			return result
		end
		unit.data.name,unit.data.maxCreeps,unit.data.type,unit.data.spawn,unit.data.respawn = "default",math.huge,"creep",120,50
		if object.map == "classic" then
			if unit.data.number == 6 then unit.data.name,unit.data.maxCreeps,unit.data.type,unit.data.spawn,unit.data.respawn = "dragon",1,"objective",150,360
			elseif unit.data.number == 12 then unit.data.name,unit.data.maxCreeps,unit.data.type,unit.data.spawn,unit.data.respawn = "nashor",1,"objective",750,420
			elseif unit.data.number == 1 or unit.data.number == 7 then unit.data.name,unit.data.maxCreeps,unit.data.type,unit.data.spawn,unit.data.respawn = "blue",3,"buff",115,300
			elseif unit.data.number == 4 or unit.data.number == 10  then unit.data.name,unit.data.maxCreeps,unit.data.type,unit.data.spawn,unit.data.respawn = "red",3,"buff",115,300
			elseif unit.data.number == 13 or unit.data.number == 14 then unit.data.name,unit.data.maxCreeps = "wight",1
			elseif unit.data.number == 2 or unit.data.number == 8 then unit.data.name,unit.data.maxCreeps = "wolf",3
			elseif unit.data.number == 3 or unit.data.number == 9  then unit.data.name,unit.data.maxCreeps = "wraith",4
			elseif unit.data.number == 5 or unit.data.number == 11 then unit.data.name,unit.data.maxCreeps = "golem",2 end
		end
		unit.data.side = unit:GetDistance(object.allySpawn) - unit:GetDistance(object.enemySpawn)
		if unit.data.side > 1000 then unit.data.side = TEAM_ENEMY elseif unit.data.side < -1000 then unit.data.side = myHero.team else unit.data.side = TEAM_NEUTRAL end
		unit.data.brother = function(number)
			if number ~= nil then for k,unit in pairs(object.creepSpawn) do if unit.data.number == number then return unit end end
			elseif object.map == "classic" then
				if unit.data.number == 2 then return unit.data.brother(13) elseif unit.data.number == 13 then return unit.data.brother(2)
				elseif unit.data.number == 3 then return unit.data.brother(5) elseif unit.data.number == 5 then return unit.data.brother(3)
				elseif unit.data.number == 8 then return unit.data.brother(14) elseif unit.data.number == 14 then return unit.data.brother(8)
				elseif unit.data.number == 9 then return unit.data.brother(11) elseif unit.data.number == 11 then return unit.data.brother(9) end
			end
			return unit
		end
		unit.data.target = function()
			local target = nil
			for k,creep in pairs(unit.data.children()) do if creep.visible == true and creep.dead == false then 
				if target == nil then target = creep
				elseif spell.buff("blessingofthelizardelder") == true and spell.buff(target,"blessingofthelizardelderslow") == true then
					if spell.buff(creep,"blessingofthelizardelderslow") == false then target = creep end
				elseif creep.maxHealth > target.maxHealth then target = creep elseif creep.maxHealth == target.maxHealth and creep.networkID > target.networkID then target = creep end
			end end
			return target
		end
		unit.data.health = function(target,range)
			range = range or math.huge
			local health = 0
			for k,creep in pairs(unit.data.children()) do
				if creep.visible == true and creep.dead == false and (target == nil or range == nil or target:GetDistance(creep) <= range) then health = health+creep.health end
			end
			return health
		end
		unit.data.composition = function(target,range) return #object.filter(unit.data.children(),{range=range,visible=true,targetable=true,dead=false,unit=target}) end
		unit.data.respawnTime = function()
			if unit.data.dead ~= true then return 0
			else return unit.data.timer + unit.data.respawn + 1 - GetInGameTimer() end
		end
		unit.data.gold = function()
			if object.map == "classic" then
				if unit.data.name == "wight" then return 65+myHero.level*0.94
				elseif unit.data.name == "blue" or unit.data.name == "red" then return 74+(GetInGameTimer()-unit.data.spawn)*0.332/60
				elseif unit.data.name == "wolf" then return 57+myHero.level*0.8
				elseif unit.data.name == "wraith" then return 48.5+myHero.level*0.67
				elseif unit.data.name == "golem" then return 70+myHero.level*0.99 
				elseif unit.data.name == "dragon" then return 205+math.min(90,myHero.level*10)
				elseif unit.data.name == "nashor" then return 300 end
			end
			return 0
		end
		unit.data.score = function(runtime) return unit.data.gold() / math.max(unit.data.respawnTime()*1.2,(2+myHero:GetDistance(unit)/myHero.ms)*(runtime or 1)) end
		AddRecvPacketCallback(function(packet)
				if packet.header == 195 then -- creepSpawn despawn
					packet.pos = 9
					if unit.data.number == packet:Decode1() then unit.data.dead,unit.data.timer = true,GetInGameTimer() end
				elseif packet.header == 233 then -- creepSpawn respawn
					packet.pos = 21
					if unit.data.number == packet:Decode1() then unit.data.dead,unit.data.timer = false,GetInGameTimer() end
				elseif unit.data.dead == nil and packet.header == 174 then -- creep vision
					packet.pos = 1
					local id = packet:DecodeF()
					for k,creep in pairs(unit.data.children()) do if creep.networkID == id then unit.data.dead,unit.data.timer = false,GetInGameTimer() end end
				end
			end)
	end
	upgrade.creepSpawn = function()
		upgrade.creepSpawn = function() end
		
		upgrade.creep()
		for k,creepSpawn in pairs(object.creepSpawn) do _creepSpawn(creepSpawn) end
		AddCreateObjCallback(function(unit) if unit.data.class == "creepSpawn" then _creepSpawn(unit) end end)
		-- routine
		timer("upgrade.creepSpawn").callback = function()
			local checker = true
			for k,creepSpawn in pairs(object.creepSpawn) do if creepSpawn.data.dead == nil and GetInGameTimer() > creepSpawn.data.spawn+1 then
				checker = false
				if myHero:GetDistance(creepSpawn) <= 285 and creepSpawn.data.target() == nil then creepSpawn.data.dead,creepSpawn.data.timer = true,GetInGameTimer() end
			end end
			if checker == true then timer("upgrade.creepSpawn").disable() end
		end
		timer("upgrade.creepSpawn").start()
		object.farmCreepSpawn = function(side,cowsep)
			local result,resultScore = nil,-math.huge
			for k,creepSpawn in pairs(object.creepSpawn) do if (side == nil or creepSpawn.data.side == side) and (myHero.level >= 3 or creepSpawn.data.name ~= "wight") then
				local creepSpawnScore = creepSpawn.data.score()
				if object.map == "classic" and cowsep == true and myHero.level >= 3 and (creepSpawn.data.name == "wolf" or creepSpawn.data.name == "wraith")
				and creepSpawn.data.brother().data.dead == false and (creepSpawn.data.target() == nil or creepSpawn.data.target().health==creepSpawn.data.target().maxHealth) then creepSpawnScore = 0
				elseif object.map == "classic" and creepSpawn.data.type == "buff" and ((myHero.parType == 0 and creepSpawn.data.name == "blue") 
				or (myHero.parType ~= 0 and creepSpawn.data.name == "red")) then creepSpawnScore = creepSpawn.data.score(0.4) end
				if creepSpawnScore > resultScore then result,resultScore = creepSpawn,creepSpawnScore end
			end end
			return result
		end
	end
	
	local _minion = function(unit)
		unit.data.healthHistory = {}
		unit.data.health = function(delay)
			local health,clock = unit.health,GetTickCount()/1000
			for time,damage in pairs(unit.data.healthHistory) do if time > clock and time < clock + delay then health = health - damage end end
			return health
		end
	end
	upgrade.minion = function()
		upgrade.minion = function() end
		
		for k,minion in pairs(object.minion) do _minion(minion) end
		AddCreateObjCallback(function(unit) if unit.data.class == "minion" then _minion(unit) end end)
		-- routine
		AddProcessSpellCallback(function(unit,data)
				-- check valid
				if data.target == nil or object.minion[data.target.hash] == nil or (object.minion[unit.hash] == nil and object.tower[unit.hash] == nil) then return end
				-- melee/barack minion
				if data.name == "Blue_Minion_BasicBasicAttack" or data.name == "Blue_Minion_BasicBasicAttack2" or data.name == "Blue_Minion_BasicBasicAttack3"
				or data.name == "Red_Minion_BasicBasicAttack" or data.name == "Red_Minion_BasicBasicAttack2" or data.name == "Red_Minion_BasicBasicAttack3"
				or data.name == "Blue_Minion_MechMeleeBasicAttack" or data.name == "Blue_Minion_MechMeleeBasicAttack2" or data.name == "Blue_Minion_MechMeleeBasicAttack3"
				or data.name == "Red_Minion_MechMeleeBasicAttack" or data.name == "Red_Minion_MechMeleeBasicAttack2" or data.name == "Red_Minion_MechMeleeBasicAttack3" then
					data.target.data.healthHistory[GetTickCount()/1000+data.windUpTime] = unit:CalcDamage(data.target,unit.totalDamage)
				-- range minion
				elseif data.name == "Blue_Minion_WizardBasicAttack" or data.name == "Blue_Minion_WizardBasicAttack2" or data.name == "Blue_Minion_WizardBasicAttack3" 
				or data.name == "Red_Minion_WizardBasicAttack" or data.name == "Red_Minion_WizardBasicAttack2" or data.name == "Red_Minion_WizardBasicAttack3" then 
					data.target.data.healthHistory[GetTickCount()/1000+data.windUpTime+target:GetDistance(unit)/650] = unit:CalcDamage(data.target,unit.totalDamage)
				-- cannon/tower minion
				elseif data.name == "Blue_Minion_MechCannonBasicAttack" or data.name == "Blue_Minion_MechCannonBasicAttack2"
				or data.name == "Red_Minion_MechCannonBasicAttack" or data.name == "Red_Minion_MechCannonBasicAttack2" 
				or data.name == "OrderTurretNormalBasicAttack" or data.name == "ChaosTurretNormalBasicAttack" then
					data.target.data.healthHistory[GetTickCount()/1000+data.windUpTime+target:GetDistance(unit)/1200] = unit:CalcDamage(data.target,unit.totalDamage)
				end
			end)
	end
	
	local _tick= function(unit)
		unit.data.time = GetTickCount()/1000
	end
	upgrade.tick = function()
		upgrade.tick = function() end
		
		for i=1,objManager.maxObjects do
			local unit = objManager:getObject(i)
			if unit ~= nil and unit.valid == true then _tick(unit) end
		end
		AddCreateObjCallback(_tick)
	end
	
	upgrade.miss = function(unit)
		unit.data.miss = 0
		timer("upgrade.miss"..unit.hash).callback = function() if unit.visible == true then unit.data.miss = 0 else unit.data.miss = unit.data.miss+1 end end
		timer("upgrade.miss"..unit.hash).cooldown = 1
		timer("upgrade.miss"..unit.hash).start()
	end
	
	
	upgrade.spell = function(unit)
		if unit.data.spellHistory == nil then
			unit.data.spellHistory = {}
			unit.data.spell = function(name)
				for key,history in pairs(unit.data.spellHistory) do if key:lower():find(name:lower()) then return history end end
				return {tick=0,windUpTime=0,animationTime=0,windUp = function() return false end,animation = function() return false end,reset = function() end}
			end
			AddProcessSpellCallback(function(obj,data) if unit.valid == true and unit.hash == obj.hash then
					local result = {name=data.name,tick=GetTickCount()/1000,windUpTime=data.windUpTime,animationTime=data.animationTime}
					if data.target ~= nil then result.target = data.target end
					if data.pos ~= nil then result.pos = VEC(data.pos.x,data.pos.z) end
					if data.startPos ~= nil then result.pos = VEC(data.startPos.x,data.startPos.z) end
					if data.endPos ~= nil then result.pos = VEC(data.endPos.x,data.endPos.z) end
					result.windUp = function() return result.tick+result.windUpTime >= GetTickCount()/1000 end
					result.animation = function() return result.tick+result.animationTime >= GetTickCount()/1000 end
					result.reset = function() unit.data.spellHistory[result.name] = nil end
					unit.data.spellHistory[result.name] = result
				end end)
		end
	end
end
-- POTION
NotLib.potion = function()
	NotLib.potion = function () end
	
	NotLib.spell() -- required for item detection
	NotLib.timer() -- required for hp/mp checks
	
	local cacheHP,cacheMP = myHero.health,myHero.mana
	timer("potion").callback = function()
		if myHero.health < cacheHP and myHero.health/myHero.maxHealth < 0.45 and spell.buff("ItemCrystalFlask","RegenerationPotion","ItemMiniRegenPotion") == false then
			local item = spell.item(2041,true) or spell.item(2003) or spell.item(2010) or spell.item(2009)
			if item ~= nil then CastSpell(item) end
		end
		if myHero.parType == 0 and myHero.mana < cacheMP and myHero.mana/myHero.maxMana < 0.33 and spell.buff("ItemCrystalFlask","FlaskOfCrystalWater") == false then
			local item =  spell.item(2041,true) or spell.item(2004) 
			if item ~= nil then CastSpell(item) end
		end
		cacheHP,cacheMP = myHero.health,myHero.mana
	end
	timer("potion").cooldown = 0.15
	timer("potion").start()
end
-- SMART SMITE
NotLib.smite = function()
	NotLib.smite = function() end
	
	NotLib.spell() -- spell collection
	NotLib.object() -- object collection
	NotLib.upgrade() -- creep detection
	
	if spell.smite ~= nil then 
		upgrade.creep()
		AddTickCallback(function()
				if myHero:CanUseSpell(spell.smite) ~= READY then return end 
				local damage = 370 + myHero.level*20
				if myHero.level > 4 then damage = damage + (myHero.level-4)*10 end
				if myHero.level > 9 then damage = damage + (myHero.level-9)*10 end
				if myHero.level > 14 then damage = damage + (myHero.level-14)*10 end
				for k,creep in pairs(object.filter(object.creep,{dead=false,targetable=true,visible=true,range=850})) do
					local name = creep.data.parent().data.name
					if (name == "red" or name == "blue" or name == "dragon" or name == "nashor")
					and creep.maxHealth > damage*2 and creep.health <= damage then CastSpell(spell.smite,creep) end
				end
			end) 
	end
end
