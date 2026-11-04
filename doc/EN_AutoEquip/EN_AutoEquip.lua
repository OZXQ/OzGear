EAE_Version = "1.1.1";
EAE_Slots = {
	"HeadSlot",
	"NeckSlot",
	"ShoulderSlot",
	"BackSlot",
	"ChestSlot",
	"ShirtSlot",
	"TabardSlot",
	"WristSlot",
	"HandsSlot",
	"WaistSlot",
	"LegsSlot",
	"FeetSlot",
	"Finger0Slot",
	"Finger1Slot",
	"Trinket0Slot",
	"Trinket1Slot",
	"MainHandSlot",
	"SecondaryHandSlot",
	"RangedSlot",
	"AmmoSlot",
}
EAE_Attach_X = 100
EAE_Attach_Y = 6
EAE_Lock = true;
EAE_SetColors = {
    [1] = {r=1,   g=0.3, b=0.3},
    [2] = {r=0.3, g=1,   b=0.3},
    [3] = {r=0.4, g=0.7, b=1  },
    [4] = {r=1,   g=1,   b=0.3},
}
StaticPopupDialogs["EAE_SAVE"] = {
	text = EAE_SAVE_CONFIRM,
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnAccept = function() EAE_SavePlayerEquipSet(EAE_GetCurrentSetId()) end,
	OnCancel = function(arg1) end,
	showAlert = 1,
	timeout = 0,
}
StaticPopupDialogs["EAE_NULL"] = {
	text = EAE_NULL_CONFIRM,
	button1 = TEXT(YES),
	button2 = TEXT(NO),
	OnAccept = function() EAE_Reset() end,
	OnCancel = function(arg1) end,
	showAlert = 1,
	timeout = 0,
}

local function to_string(str)
    if str ~= nil then
        if type(str) == "table" then
            return "<table>";
        elseif type(str) == "function" then
            return "<function>";
        else
            return tostring(str)
        end
    else
        return "<nil>"
    end
end

local function debug_print(txt)
    local _, class = UnitClass("player")
    local color = RAID_CLASS_COLORS[class].colorStr
    if (DEFAULT_CHAT_FRAME) then
        DEFAULT_CHAT_FRAME:AddMessage("|cffffd200E|c" .. color .. "AE|r - " .. txt)
    end
end

local function EAE_GameTooltip_AddNewbieTip(normalText, r, g, b, newbieText, noNormalText)
	if (newbieText ~= nil) then
		GameTooltip_SetDefaultAnchor(GameTooltip, this);
		if (normalText) then
			GameTooltip:SetText(normalText, r, g, b);
			GameTooltip:AddLine(newbieText, NORMAL_FONT_COLOR.r, NORMAL_FONT_COLOR.g, NORMAL_FONT_COLOR.b, 1);
		else
			GameTooltip:SetText(newbieText, r, g, b, 1, 1);
		end
		GameTooltip:Show();
	else
		if (not noNormalText) then
			GameTooltip:SetOwner(this, "ANCHOR_RIGHT");
			GameTooltip:SetText(normalText, r, g, b);
		end
	end
end

local function getPlayerFrame()
	if LUFUnitplayer then
		return LUFUnitplayer
	elseif pfUI and pfUI.uf and pfUI.uf.player then
		return pfUI.uf.player
	else
		return PlayerFrame
	end
end

function EAE_Display_EAE_Frame_Info()
	local frame = EAE_Frame;
	if (frame) then
		local left, top, right, bottom = frame:GetLeft(), frame:GetTop(), frame:GetRight(), frame:GetBottom();
		local str = format("x = %d, y = %d, w = %d, h = %d", left, top, (right - left), (top - bottom));
		debug_print("EAE_Frame:Rect(): "..str);
		local playerFrame = getPlayerFrame()
		left, top, right, bottom = playerFrame:GetLeft(), playerFrame:GetTop(), playerFrame:GetRight(), playerFrame:GetBottom();
		str = format("x = %d, y = %d, w = %d, h = %d", left, top, (right - left), (top - bottom));
		debug_print("PlayerFrame:Rect(): "..str);
		debug_print("EAE_Frame:IsMovable(): "..to_string(frame:IsMovable()));
		debug_print("EAE_Frame:EnableMouse(): "..to_string(frame:IsMouseEnabled()));
	end
end

function EAE_CheckNeedAttachToPlayerFrame(frame)
	local diffuseX, minDiffuseY, maxDiffuseY = 10, -20, 2;
	local playerFrame = getPlayerFrame()
	if playerFrame ~= nil then
		local deltaX, deltaY;
		local left, top = frame:GetLeft(), frame:GetTop();
		local pleft, ptop = playerFrame:GetLeft(), playerFrame:GetTop();
		deltaX = left - pleft;
		deltaY = top - ptop;
		if deltaX > (EAE_Attach_X - diffuseX) and deltaX < (EAE_Attach_X + diffuseX) then
			if deltaY > (EAE_Attach_Y + minDiffuseY) and deltaY < (EAE_Attach_Y + maxDiffuseY) then
				frame:ClearAllPoints();
				frame:SetPoint("TOPLEFT", playerFrame, "TOPLEFT", EAE_Attach_X, EAE_Attach_Y);
			end
		end
	end
end

function EAE_OnLoad()
    this:RegisterEvent("ADDON_LOADED");
    this:RegisterEvent("PLAYER_ENTERING_WORLD");
    this:RegisterEvent("BAG_UPDATE");        -- ← 新增这一行
    if (not EAE_Config) then
        EAE_Config = {};
    end;
    EAE_RealmName = GetCVar("realmName");
    if (not EAE_RealmName) then
        EAE_RealmName = "Enigma";
    end;
    EAE_PlayerName = UnitName("player");
    if (not EAE_PlayerName) then
        EAE_PlayerName = "Unknown";
    end;
    EAE_PlayerId = EAE_PlayerName .. "@" .. EAE_RealmName;

    SLASH_EAE1 = "/eae";
    SlashCmdList["EAE"] = EAE_Command;
end

function EAE_OnEvent(event)
    if (event == "ADDON_LOADED" and arg1 == "EN_AutoEquip") then
        setId = EAE_GetCurrentSetId();
        if (not setId or setId == 0) then
        else
            local objSetButton = getglobal("EAE_FrameSetButton" .. setId);
            if (objSetButton) then
                objSetButton:SetChecked(1);
            end;
        end;
        if (EUF_Options) then
            EAE_FrameTexture:SetTexture("Interface\\AddOns\\EN_AutoEquip\\EN_AutoEquip");
        end
        if (EAE_Frame) then
            EAE_Frame:SetMovable(true);
            EAE_Frame:EnableMouse(true);
        end
        EAE_Lock = false;
        EAE_HookTooltip()    -- ← 新增这一行
    elseif (event == "PLAYER_ENTERING_WORLD") then
        if (EAE_Frame) then
            if LUFUnitplayer then
                EAE_Attach_X = 0
                EAE_Attach_Y = 24
                EAE_Frame:SetParent(LUFUnitplayer)
                EAE_Frame:Show()
            elseif pfUI and pfUI.uf and pfUI.uf.player then
                EAE_Attach_X = 0
                EAE_Attach_Y = 24
                EAE_Frame:SetParent(pfUI.uf.player)
                EAE_Frame:Show()
            end
            EAE_CheckNeedAttachToPlayerFrame(EAE_Frame);
        end
    end
end

function EAE_SetButton_OnClick(setId)
	if (CursorHasItem() or UnitIsDeadOrGhost("player")) then
		return;
	end
	if (setId == 1) then
		EAE_FrameSetButton1:SetChecked(1);
		EAE_FrameSetButton2:SetChecked(nil);
		EAE_FrameSetButton3:SetChecked(nil);
		EAE_FrameSetButton4:SetChecked(nil);
		EAE_FrameNakedButton:SetChecked(nil);
		NakedObj.Nakie = false;
	elseif (setId == 2) then
		EAE_FrameSetButton1:SetChecked(nil);
		EAE_FrameSetButton2:SetChecked(1);
		EAE_FrameSetButton3:SetChecked(nil);
		EAE_FrameSetButton4:SetChecked(nil);
		EAE_FrameNakedButton:SetChecked(nil);
		NakedObj.Nakie = false;
	elseif (setId == 3) then
		EAE_FrameSetButton1:SetChecked(nil);
		EAE_FrameSetButton2:SetChecked(nil);
		EAE_FrameSetButton3:SetChecked(1);
		EAE_FrameSetButton4:SetChecked(nil);
		EAE_FrameNakedButton:SetChecked(nil);
		NakedObj.Nakie = false;
	elseif (setId == 4) then
		EAE_FrameSetButton1:SetChecked(nil);
		EAE_FrameSetButton2:SetChecked(nil);
		EAE_FrameSetButton3:SetChecked(nil);
		EAE_FrameSetButton4:SetChecked(1);
		EAE_FrameNakedButton:SetChecked(nil);
		NakedObj.Nakie = false;
	elseif (setId == 5) then
		local id = EAE_GetCurrentSetId()
		EAE_FrameSetButton1:SetChecked(nil);
		EAE_FrameSetButton2:SetChecked(nil);
		EAE_FrameSetButton3:SetChecked(nil);
		EAE_FrameSetButton4:SetChecked(nil);
		getglobal("EAE_FrameSetButton"..id):SetChecked(1);
		EAE_FrameNakedButton:SetChecked(nil);
		NakedObj.Nakie = false;
	else
		EAE_FrameSetButton1:SetChecked(nil);
		EAE_FrameSetButton2:SetChecked(nil);
		EAE_FrameSetButton3:SetChecked(nil);
		EAE_FrameSetButton4:SetChecked(nil);
	end
	if (setId ~= nil and setId > 0 and setId < 5) then
		EAE_LoadPlayerEquipSet(setId, 1);
		PlaySound("igChatEmoteButton");
	end
end

function EAE_SaveButton_OnClick(arg1)
	if (not IsShiftKeyDown()) then
		if (arg1 == "LeftButton") then
			local id = EAE_GetCurrentSetId();
			if (id < 1 or id > 4) then
				DEFAULT_CHAT_FRAME:AddMessage(BINDING_HEADER_EAE_TITLE..": "..string.format(EAE_MSG_NULL_SAVED, setId), 1, 0.75 , 0);
				return
			end
			StaticPopup_Show("EAE_SAVE");
		elseif (arg1 == "RightButton") then
			StaticPopup_Show("EAE_NULL");
		end
	end
end

function EAE_NakedButton_OnClick()
	SlashCmdList.NAKEDTOGGLE();
	if (this:GetChecked()) then
		EAE_SetButton_OnClick()
	else
		EAE_SetButton_OnClick(5)
	end
end

function EAE_SaveButton_OnEnter()
	EAE_GameTooltip_AddNewbieTip(EAE_HELP_SAVE_BTN_TITLE, 1, 1, 1, EAE_HELP_SAVE_BTN_DESC);
end

function EAE_NakedButton_OnEnter()
	EAE_GameTooltip_AddNewbieTip(EAE_HELP_NAKED_BTN_TITLE, 1, 1, 1, EAE_HELP_NAKED_BTN_DESC);
end

function EAE_SetButton_OnEnter(arg1)
	EAE_GameTooltip_AddNewbieTip(string.format(EAE_HELP_SET_BTN_TITLE, arg1), 1, 1, 1, string.format(EAE_HELP_SET_BTN_DESC, arg1));
end

function EAE_Reset()
    EAE_Config[EAE_PlayerId] = {};
    EAE_SetCurrentSetId(0);
    EAE_FrameSetButton1:SetChecked(nil);
    EAE_FrameSetButton2:SetChecked(nil);
    EAE_FrameSetButton3:SetChecked(nil);
    EAE_FrameSetButton4:SetChecked(nil);
end

function EAE_SavePlayerEquipSet(setId)
    local index, value;
    local equipSet = EAE_GetPlayerEquipSet(setId);
    for index, value in pairs(EAE_Slots) do
        local itemName, itemLinkId = EAE_GetItemInfo("inventory", value);
        if (itemName and itemLinkId) then
            equipSet[value] = {name = itemName, link = itemLinkId};
        else
            equipSet[value] = {name = nil, link = nil};
        end
    end
    DEFAULT_CHAT_FRAME:AddMessage(BINDING_HEADER_EAE_TITLE..": "..string.format(EAE_MSG_SET_SAVED, setId), 1, 0.75 , 0);
end

function EAE_LoadPlayerEquipSet(setId, showMsg)
	EAE_GetPlayerItems()
	local equipSet = EAE_GetPlayerEquipSet(setId)
	if (not equipSet) then
		EAE_SetCurrentSetId(setId);
		return
	end
	EAE_LoadSet = {}
	EAE_LoadSetFirst = {}
	if (showMsg == 1) then
		DEFAULT_CHAT_FRAME:AddMessage(BINDING_HEADER_EAE_TITLE..": "..string.format(EAE_MSG_LOAD_SET, setId), 1, 0.75 , 0);
	end
	local slotName, itemData
	local UnequipItems = {};
	for slotName, itemData in pairs(equipSet) do
		if (itemData.link) then
			local srcSlot = EAE_PlayerItems[itemData.link]
			if (srcSlot) then
				local dstSlot = {}
				dstSlot.type = "inventory";
				dstSlot.slotId = GetInventorySlotInfo(slotName);
				if (EAE_MustPickUp(srcSlot, dstSlot, setId)) then
					if (srcSlot.type == "inventory") then
							local index, s, b
							for index,s in pairs(EAE_LoadSetFirst) do
								if (EAE_IsSlotEqual(dstSlot, s.srcSlot)) then
									table.remove(EAE_LoadSetFirst, index)
									EAE_SaveItemPareToLoadSet(srcSlot, dstSlot, 1)
									b = true;
									break;
								end
							end
						if (not b) then
							EAE_SaveItemPareToLoadSet(srcSlot, dstSlot, 0)
						end
					elseif (EAE_IfExist(srcSlot)) then
						local srcSlot2 = EAE_PlayerItems[itemData.link..":2"];
						if (srcSlot2) then
							if (srcSlot2.type == "inventory") then
								if (not EAE_IsSlotEqual(srcSlot2, dstSlot)) then
									EAE_SaveItemPareToLoadSet(srcSlot2, dstSlot, 0)
								end
							else
								EAE_SaveItemPareToLoadSet(srcSlot2, dstSlot, 1)
							end
						else
							EAE_SaveItemPareToLoadSet(srcSlot, dstSlot, 1)
						end
					else
						EAE_SaveItemPareToLoadSet(srcSlot, dstSlot, 1)
					end
				end
			else
				if (showMsg == 1) then
					DEFAULT_CHAT_FRAME:AddMessage(string.format(EAE_MSG_ITEM_NOTEXISTS, itemData.name), 1, 0.75, 0);
				end;
			end
		elseif (slotName ~= "AmmoSlot" and GetInventorySlotInfo(slotName)) then
			local dstSlot = {}
			dstSlot.type = "inventory";
			dstSlot.slotId = GetInventorySlotInfo(slotName);
			table.insert(UnequipItems, dstSlot);
		end
	end
	if (EAE_IsLoadSetLocked() and showMsg == 1) then
		DEFAULT_CHAT_FRAME:AddMessage(EAE_MSG_ITEM_LOCKED, 1, 0.75, 0);
		return;
	end;
	local index, value, slotPare, slot2
	EAE_GetBagEmptyNums();
	for index, slotPare in pairs(EAE_LoadSetFirst) do
		if (TotalBagEmptyNums == 0 and showMsg == 1) then
			DEFAULT_CHAT_FRAME:AddMessage(EAE_MSG_BAG_FULL, 1, 0.75, 0);
			break;
		end
		EAE_PickUpItem(slotPare.dstSlot)
		if (CursorHasItem()) then
			for bag = 0, 4 do
				if (BagEmptyNums[bag] > 0) then
					if (bag == 0) then
						PutItemInBackpack();
					else
						PutItemInBag(19+bag);
					end
					BagEmptyNums[bag] = BagEmptyNums[bag] - 1;
					TotalBagEmptyNums = TotalBagEmptyNums - 1;
					break;
				end
			end
		end
		EAE_PickUpItem(slotPare.srcSlot)
		if (CursorHasItem()) then
			EquipCursorItem(slotPare.dstSlot.slotId-1)
		end
	end
	for index, slotPare in pairs(EAE_LoadSet) do
		EAE_PickUpItem(slotPare.srcSlot)
		if (CursorHasItem()) then
			EAE_PickUpItem(slotPare.dstSlot)
		end
	end
	for index, slot2 in pairs(UnequipItems) do
		if (TotalBagEmptyNums == 0 and showMsg == 1) then
			DEFAULT_CHAT_FRAME:AddMessage(EAE_MSG_BAG_FULL, 1, 0.75, 0);
			break;
		end
		EAE_PickUpItem(slot2)
		if (CursorHasItem()) then
			for bag = 0, 4 do
				if (BagEmptyNums[bag] > 0) then
					if (bag == 0) then
						PutItemInBackpack();
					else
						PutItemInBag(19+bag);
					end
					BagEmptyNums[bag] = BagEmptyNums[bag] - 1;
					TotalBagEmptyNums = TotalBagEmptyNums - 1;
					break;
				end
			end
		end
	end
	EAE_PlayerItems = {};
	EAE_LoadSet = {};
	EAE_LoadSetFirst = {};
	EAE_SetCurrentSetId(setId)
end

function EAE_IfExist(slot)
	for _,s in pairs(EAE_LoadSet) do
		if (EAE_IsSlotEqual(slot, s.srcSlot)) then return true; end
	end
	return false;
end

function EAE_GetBagEmptyNums()
	local bag, totalSlots, slot;
	BagEmptyNums = {};
	TotalBagEmptyNums = 0;
	for bag = 0, 4 do
		BagEmptyNums[bag] = 0;
		totalSlots = GetContainerNumSlots(bag);
		for slot=1, totalSlots do
			if not GetContainerItemInfo(bag, slot) then
				BagEmptyNums[bag] = BagEmptyNums[bag] + 1;
				TotalBagEmptyNums = TotalBagEmptyNums + 1;
			end
		end
	end
end

function EAE_MustPickUp(srcSlot, dstSlot, setId)
	if (srcSlot.type == "container") then
		return 1;
	else
		if (EAE_IsSlotEqual(srcSlot, dstSlot)) then
			return;
		end
		return 1;
	end
end

function EAE_GetSetItemInventorySlot(itemLinkId, setId)
	local equipSet = EAE_GetPlayerEquipSet(setId);
	if (not equipSet) then
		return;
	end
	local slotName, itemData;
	for slotName, itemData in equipSet do
		if (itemData.link == itemLinkId) then
			local slot = {};
			slot.type = "inventory";
			slot.slotId = GetInventorySlotInfo(slotName);
			return slot;
		end
	end
end

function EAE_SaveItemPareToLoadSet(srceLoc, destLoc, flag)
	local index, value, TempLoadSet
	if (flag == 0) then
		TempLoadSet = EAE_LoadSetFirst;
	else
		TempLoadSet = EAE_LoadSet;
	end
	for index, itemPare in pairs(TempLoadSet) do
		if (EAE_IsSlotEqual(itemPare.srcSlot, srceLoc) and EAE_IsSlotEqual(itemPare.dstSlot, destLoc)) then
			return;
		end
		if (EAE_IsSlotEqual(itemPare.srcSlot, destLoc) and EAE_IsSlotEqual(itemPare.dstSlot, srceLoc)) then
			return;
		end
	end
	local itemPare = {}
	itemPare.srcSlot = srceLoc;
	itemPare.dstSlot = destLoc;
	table.insert(TempLoadSet, itemPare);
end

function EAE_IsSlotEqual(slot1, slot2)
	return (slot1.type == slot2.type and slot1.bagId == slot2.bagId and slot1.slotId == slot2.slotId)
end

function EAE_IsSlotItemLocked(slot)
	if (slot.type == "container") then
		local _, _, isLocked, _, _ = GetContainerItemInfo(slot.bagId, slot.slotId);
		return isLocked;
	elseif (slot.type == "inventory") then
		return IsInventoryItemLocked(slot.slotId);
	end
end

function EAE_IsLoadSetLocked()
	local index, itemPare
	for index, itemPare in pairs(EAE_LoadSet) do
		if (EAE_IsSlotItemLocked(itemPare.srcSlot) or EAE_IsSlotItemLocked(itemPare.dstSlot)) then
			return 1;
		end
	end
end

function EAE_PickUpItem(slot)
	if (slot.type == "container") then
		PickupContainerItem(slot.bagId, slot.slotId)
	elseif (slot.type == "inventory") then
		PickupInventoryItem(slot.slotId)
	end
end

function EAE_GetPlayerItems()
	EAE_PlayerItems = {};
	local bagIndex;
	for bagIndex = 0, NUM_CONTAINER_FRAMES, 1 do
		local slotIndex;
		for slotIndex = 1, GetContainerNumSlots(bagIndex), 1 do
			local itemName, itemLinkId = EAE_GetItemInfo("container", bagIndex, slotIndex);
			if (itemName and itemLinkId) then
				local slot = {};
				slot.type = "container";
				slot.bagId = bagIndex;
				slot.slotId = slotIndex;
				if (EAE_PlayerItems[itemLinkId]) then
					EAE_PlayerItems[itemLinkId..":2"] = slot;
				else
					EAE_PlayerItems[itemLinkId] = slot;
				end
			end;
		end;
	end;
	local index, value;
	for index, slotName in pairs(EAE_Slots) do
		local itemName, itemLinkId = EAE_GetItemInfo("inventory", slotName);
		if (itemName and itemLinkId) then
			local slot = {};
			slot.type = "inventory";
			slot.slotId = GetInventorySlotInfo(slotName);
			if (EAE_PlayerItems[itemLinkId]) then
				EAE_PlayerItems[itemLinkId..":2"] = slot;
			else
				EAE_PlayerItems[itemLinkId] = slot;
			end
		end;
	end;
end;

function EAE_GetPlayerEquipSet(setId)
	local numSetId = tonumber(setId)
	if (not numSetId) then
		return
	end
	if (not EAE_Config[EAE_PlayerId][numSetId]) then
		EAE_Config[EAE_PlayerId][numSetId] = {}
	end
	return EAE_Config[EAE_PlayerId][numSetId]
end

function EAE_GetCurrentSetId()
	if (not EAE_Config[EAE_PlayerId]) then
		EAE_Config[EAE_PlayerId] = {};
	end;
	if (not EAE_Config[EAE_PlayerId].CurrentSetId) then
		EAE_Config[EAE_PlayerId].CurrentSetId = 0;
	end;
	return EAE_Config[EAE_PlayerId].CurrentSetId;
end;

function EAE_SetCurrentSetId(setId)
	if (not EAE_Config[EAE_PlayerId]) then
		EAE_Config[EAE_PlayerId] = {};
	end;
	EAE_Config[EAE_PlayerId].CurrentSetId = setId;
end;

function EAE_GetInventoryItemLinkId(slotId)
	local itemLink = GetInventoryItemLink("player", slotId);
	local itemName, itemLinkId = EAE_GetItemInfoByLink(itemLink);
	return itemLinkId;
end

function EAE_GetItemInfoByLink(itemLink)
	if (not itemLink or type(itemLink) ~= "string") then
		return;
	end
	local _, _, itemLinkId, itemName = string.find(itemLink, "^|c%x+|H(.+)|h%[(.+)%]");
	if (itemLinkId and itemName) then
		return itemName, itemLinkId;
	end
end

function EAE_GetItemInfo(itemType, arg1, arg2)
	if (itemType == "container") then
		local itemLink = GetContainerItemLink(arg1, arg2)
		return EAE_GetItemInfoByLink(itemLink)
	elseif (itemType == "inventory") then
		local itemLink = GetInventoryItemLink("player", GetInventorySlotInfo(arg1))
		return EAE_GetItemInfoByLink(itemLink)
	end
end

function EAE_DEBUG(arg1,arg2)
	local msg = "";
	if (arg1) then msg = msg .. arg1; end;
	if (arg2) then msg = msg .. "=" .. arg2; end;
	DEFAULT_CHAT_FRAME:AddMessage(msg);
end;

function EAE_Command(cmd)
    if (cmd == "lock") then
        EAE_Frame:SetMovable(false);
        EAE_Frame:EnableMouse(false);
        EAE_Lock = true;
        DEFAULT_CHAT_FRAME:AddMessage("EN_AutoEquip 窗口已锁定");
    elseif (cmd == "unlock") then
        EAE_Frame:SetMovable(true);
        EAE_Frame:EnableMouse(true);
        EAE_Lock = false;
        DEFAULT_CHAT_FRAME:AddMessage("EN_AutoEquip 窗口已解锁");
    elseif (cmd == "check") then
        if not EAE_Config then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444EAE: EAE_Config 不存在，存档可能未加载|r");
            return;
        end
        DEFAULT_CHAT_FRAME:AddMessage("|cffffff00EAE: 当前角色 ID = " .. tostring(EAE_PlayerId) .. "|r");
        local foundOtherKeys = false;
        for k, _ in pairs(EAE_Config) do
            if k ~= EAE_PlayerId and type(k) == "string" then
                DEFAULT_CHAT_FRAME:AddMessage("|cffaaaaaaEAE: 发现其它存档 key: " .. tostring(k) .. "|r");
                foundOtherKeys = true;
            end
        end
        if not EAE_Config[EAE_PlayerId] then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444EAE: 当前角色无存档数据|r");
            if foundOtherKeys then
                DEFAULT_CHAT_FRAME:AddMessage("|cffffff00EAE: 但发现其它 key，可能是旧版插件残留数据|r");
            end
            return;
        end
        local hasAny = false;
        for setId = 1, 4 do
            local equipSet = EAE_Config[EAE_PlayerId][setId];
            if equipSet and next(equipSet) then
                hasAny = true;
                local equipped, broken = 0, 0;
                for slotName, itemData in pairs(equipSet) do
                    if type(itemData) ~= "table" then
                        broken = broken + 1;
                        DEFAULT_CHAT_FRAME:AddMessage(
                            "|cffff4444EAE: 套装" .. setId .. " 槽[" .. slotName .. "] 数据类型异常: " .. type(itemData) .. "|r"
                        );
                    elseif itemData.link then
                        equipped = equipped + 1;
                    end
                end
                local c = EAE_SetColors[setId];
                local hex = string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255);
                if broken > 0 then
                    DEFAULT_CHAT_FRAME:AddMessage(hex .. "EAE 套装" .. setId .. "|r: " ..
                        "|cffff4444" .. broken .. " 槽数据损坏，建议重新保存|r （已装备 " .. equipped .. " 件）");
                else
                    DEFAULT_CHAT_FRAME:AddMessage(hex .. "EAE 套装" .. setId .. "|r: " ..
                        "|cff88ff88OK|r （已装备 " .. equipped .. " 件）");
                end
            else
                DEFAULT_CHAT_FRAME:AddMessage("|cff888888EAE 套装" .. setId .. ": 未保存|r");
            end
        end
        if not hasAny then
            DEFAULT_CHAT_FRAME:AddMessage("|cffff4444EAE: 所有套装均为空，请先保存套装|r");
        end
    else
        DEFAULT_CHAT_FRAME:AddMessage("Usage: /eae [lock|unlock|check]");
    end
end

function EAE_SaveButton_OnDragStart(button)
	local frame = EAE_Frame;
	if (frame) then
		if ((button == "LeftButton") and IsShiftKeyDown() and (EAE_Lock == false)) then
			frame.isMoving = true;
			frame:ClearAllPoints();
			frame:StartMoving();
		end
	end
end

function EAE_SaveButton_OnDragStop(button)
	local frame = EAE_Frame;
	if (frame and frame.isMoving) then
		frame:StopMovingOrSizing();
		frame.isMoving = false;
		if (IsShiftKeyDown() and (EAE_Lock == false)) then
			EAE_CheckNeedAttachToPlayerFrame(frame);
		end
	end
end

function EAE_SaveButton_OnHide()
	local frame = EAE_Frame;
	if (frame and frame.isMoving) then
		frame:StopMovingOrSizing();
		frame.isMoving = false;
	end
end

function EAE_MouseDown(button)
	if (EAE_Lock == false and (button == "LeftButton")) then
		this.isMoving = true;
		this:StartMoving();
	end
end

function EAE_MouseUp()
	if (this.isMoving) then
		this:StopMovingOrSizing();
		this.isMoving = false;
	end
end

function EAE_OnShow()
end

function EAE_OnHide()
	if (this.isMoving) then
		this:StopMovingOrSizing();
		this.isMoving = false;
	end
end

function EAE_GetSetItemsLookup()
    local lookup = {}
    if not EAE_Config or not EAE_PlayerId or not EAE_Config[EAE_PlayerId] then
        return lookup
    end
    for setId = 1, 4 do
        local equipSet = EAE_Config[EAE_PlayerId][setId]
        if equipSet then
            for slotName, itemData in pairs(equipSet) do
                if itemData and itemData.link then
                    if not lookup[itemData.link] then
                        lookup[itemData.link] = {}
                    end
                    local found = false
                    for _, id in pairs(lookup[itemData.link]) do
                        if id == setId then found = true; break end
                    end
                    if not found then
                        table.insert(lookup[itemData.link], setId)
                        table.sort(lookup[itemData.link])
                    end
                end
            end
        end
    end
    return lookup
end

function EAE_HookTooltip()
    local badge = CreateFrame("Frame", "EAE_TooltipBadge", UIParent)
    badge:SetFrameStrata("TOOLTIP")
	badge:SetHeight(20)
    badge:Hide()
    local bg = badge:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(badge)
    bg:SetTexture(0, 0, 0, 0.7)
    local fs = badge:CreateFontString(nil, "OVERLAY")
	fs:SetFont("Fonts\\FRIZQT__.TTF", 14, "OUTLINE")
    fs:SetPoint("LEFT", badge, "LEFT", 4, 0)
    fs:SetPoint("RIGHT", badge, "RIGHT", -4, 0)
    fs:SetJustifyH("LEFT")
    badge.label = fs
    local function updateBadge(itemLink)
        if not EAE_PlayerId then badge:Hide(); return end
        local _, itemLinkId = EAE_GetItemInfoByLink(itemLink)
        if not itemLinkId then badge:Hide(); return end
        local lookup = EAE_GetSetItemsLookup()
        if not lookup[itemLinkId] then badge:Hide(); return end
        local parts = {}
        for _, setId in pairs(lookup[itemLinkId]) do
            local c = EAE_SetColors[setId]
            local hex = string.format("|cff%02x%02x%02x", c.r*255, c.g*255, c.b*255)
            table.insert(parts, hex .. "◆ 套装 " .. setId .. "|r")
        end
        local text = table.concat(parts, "   ")
        badge.label:SetText(text)
        badge:SetWidth(GameTooltip:GetWidth())
        badge:ClearAllPoints()
		badge:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", 0, -2)
        badge:Show()
    end
    local origSetBagItem = GameTooltip.SetBagItem
    GameTooltip.SetBagItem = function(self, bag, slot)
        origSetBagItem(self, bag, slot)
        updateBadge(GetContainerItemLink(bag, slot))
    end
    local origHide = GameTooltip.Hide
    GameTooltip.Hide = function(self)
        origHide(self)
        badge:Hide()
    end
end