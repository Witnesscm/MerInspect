
-------------------------------------
-- 顯示寶石和附魔信息
-- @Author: M
-- @DepandsOn: InspectUnit.lua
-------------------------------------

local addon, ns = ...
local L = ns.L

local LibItemGem = LibStub:GetLibrary("LibItemGem.7000")
local LibSchedule = LibStub:GetLibrary("LibSchedule.7000")
local LibItemEnchant = LibStub:GetLibrary("LibItemEnchant.7000")

local EnchantParts = {
    [1] = HEADSLOT,
    [3] = SHOULDERSLOT,
    [5]  = CHESTSLOT,
    [7] = LEGSSLOT,
    [8]  = FEETSLOT,
    [9]  = WRISTSLOT,
    [10] = HANDSSLOT,
    [15] = BACKSLOT,
    [16] = MAINHANDSLOT,
    [17] = SECONDARYHANDSLOT,
}

if ns.IsClassic then
    EnchantParts = {
        [5]  = CHESTSLOT,
        [8]  = FEETSLOT,
        [9]  = WRISTSLOT,
        [10] = HANDSSLOT,
        [15] = BACKSLOT,
        [16] = MAINHANDSLOT,
        [17] = SECONDARYHANDSLOT,
    }
end

--創建圖標框架
local function CreateIconFrame(frame, index)
    local icon = CreateFrame("Button", nil, frame)
    icon.index = index
    icon:Hide()
    icon:SetSize(16, 16)
    icon:SetScript("OnEnter", function(self)
        if (self.itemLink) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetHyperlink(self.itemLink)
            GameTooltip:Show()
        elseif (self.spellID) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetSpellByID(self.spellID)
            GameTooltip:Show()
        elseif (self.title) then
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText(self.title)
            GameTooltip:Show()
        end
    end)
    icon:SetScript("OnLeave", function(self)
        GameTooltip:Hide()
    end)
    icon:SetScript("OnDoubleClick", function(self)
        if (self.itemLink or self.title) then
            ChatEdit_ActivateChat(ChatEdit_ChooseBoxForSend())
            ChatEdit_InsertLink(self.itemLink or self.title)
        end
    end)
    icon.bg = icon:CreateTexture(nil, "BACKGROUND")
    icon.bg:SetSize(16, 16)
    icon.bg:SetPoint("CENTER")
    icon.bg:SetTexture("Interface\\AddOns\\"..addon.."\\texture\\GemBg")
    icon.texture = icon:CreateTexture(nil, "BORDER")
    icon.texture:SetSize(12, 12)
    icon.texture:SetPoint("CENTER")
    icon.texture:SetMask("Interface\\FriendsFrame\\Battlenet-Portrait")
    frame["xicon"..index] = icon
    return frame["xicon"..index]
end

--隱藏所有圖標框架
local function HideAllIconFrame(frame)
    local index = 1
    while (frame["xicon"..index]) do
        frame["xicon"..index].title = nil
        frame["xicon"..index].itemLink = nil
        frame["xicon"..index].spellID = nil
        frame["xicon"..index]:Hide()
        index = index + 1
    end
    LibSchedule:RemoveTask("InspectGemAndEnchant", true)
end

--獲取可用的圖標框架
local function GetIconFrame(frame)
    local index = 1
    while (frame["xicon"..index]) do
        if (not frame["xicon"..index]:IsShown()) then
            return frame["xicon"..index]
        end
        index = index + 1
    end
    return CreateIconFrame(frame, index)
end

--執行圖標更新
local function onExecute(self)
    if (self.dataType == "item") then
        local _, itemLink, quality, _, _, _, _, _, _, texture = GetItemInfo(self.data)
        if (texture) then
            local r, g, b = GetItemQualityColor(quality or 0)
            self.icon.bg:SetVertexColor(r, g, b)
            self.icon.texture:SetTexture(texture)
            if (not self.icon.itemLink) then
                self.icon.itemLink = itemLink
            end
            return true
        end
    elseif (self.dataType == "spell") then
        local _, _, texture = GetSpellInfo(self.data)
        if (texture) then
            self.icon.texture:SetTexture(texture)
            return true
        end
    end
end

--Schedule模式更新圖標
local function UpdateIconTexture(icon, texture, data, dataType)
    if (not texture) then
        LibSchedule:AddTask({
            identity  = "InspectGemAndEnchant" .. icon.index,
            timer     = 0.1,
            elasped   = 0.5,
            expired   = GetTime() + 3,
            onExecute = onExecute,
            icon      = icon,
            data      = data,
            dataType  = dataType,
        })
    end
end

--讀取並顯示圖標
local function ShowGemAndEnchant(frame, ItemLink, anchorFrame, itemframe, unit)
    if (not ItemLink) then return 0 end
    local num, info = 0 , {}
    local _, quality, texture, icon, r, g, b
    if not ns.IsClassic then
        num, info = LibItemGem:GetItemGemInfo(ItemLink, unit, itemframe.index)
    end
    for i, v in ipairs(info) do
        icon = GetIconFrame(frame)
        if (v.link) then
            _, _, quality, _, _, _, _, _, _, texture = GetItemInfo(v.link)
            r, g, b = GetItemQualityColor(quality or 0)
            icon.bg:SetVertexColor(r, g, b, 1)
            icon.texture:SetTexture(texture or "Interface\\Cursor\\Quest")
            UpdateIconTexture(icon, texture, v.link, "item")
        elseif (v.texture) then
            icon.bg:SetVertexColor(1, 1, 1, 0.8)
            icon.texture:SetTexture(v.texture)
        else
            icon.bg:SetVertexColor(1, 0.82, 0, 0.5)
            icon.texture:SetTexture("Interface\\Cursor\\Quest")
        end
        icon.title = v.name
        icon.itemLink = v.link
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", anchorFrame, "RIGHT", i == 1 and 6 or 1, 0)
        icon:Show()
        anchorFrame = icon
    end
    local enchantItemID, enchantSpellID, enchantID = LibItemEnchant:GetEnchantInfo(ItemLink, itemframe.index)
    if (enchantItemID) then
        num = num + 1
        icon = GetIconFrame(frame)
        _, ItemLink, quality, _, _, _, _, _, _, texture = GetItemInfo(enchantItemID)
        r, g, b = GetItemQualityColor(quality or 0)
        icon.bg:SetVertexColor(r, g, b, 1)
        icon.texture:SetTexture(texture)
        UpdateIconTexture(icon, texture, enchantItemID, "item")
        icon.itemLink = ItemLink
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", anchorFrame, "RIGHT", num == 1 and 6 or 1, 0)
        icon:Show()
        anchorFrame = icon
    elseif (enchantSpellID) then
        num = num + 1
        icon = GetIconFrame(frame)
        _, _, texture = GetSpellInfo(enchantSpellID)
        icon.bg:SetVertexColor(1, 0.82, 0, 1)
        icon.texture:SetTexture(texture)
        UpdateIconTexture(icon, texture, enchantSpellID, "spell")
        icon.spellID = enchantSpellID
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", anchorFrame, "RIGHT", num == 1 and 6 or 1, 0)
        icon:Show()
        anchorFrame = icon
    elseif (enchantID) then
        num = num + 1
        icon = GetIconFrame(frame)
        icon.title = "#" .. enchantID
        icon.bg:SetVertexColor(0.1, 0.1, 0.1, 1)
        icon.texture:SetTexture("Interface\\FriendsFrame\\InformationIcon")
        icon:ClearAllPoints()
        icon:SetPoint("LEFT", anchorFrame, "RIGHT", num == 1 and 6 or 1, 0)
        icon:Show()
        anchorFrame = icon
    elseif (not enchantID and EnchantParts[itemframe.index]) then
        local itemEquip = select(9, GetItemInfo(ItemLink))
        if (itemframe.index ~= INVSLOT_OFFHAND) or (itemEquip ~= "INVTYPE_HOLDABLE") then
            num = num + 1
            icon = GetIconFrame(frame)
            icon.title = ENCHANTS .. ": " .. EnchantParts[itemframe.index]
            icon.bg:SetVertexColor(1, 0.2, 0.2, 0.6)
            icon.texture:SetTexture("Interface\\Cursor\\Quest")
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", anchorFrame, "RIGHT", num == 1 and 6 or 1, 0)
            icon:Show()
            anchorFrame = icon
        end
    elseif not ns.IsClassic and itemframe.index == INVSLOT_WAIST then
        local gemNum = LibItemGem:GetItemGemInfo(ItemLink)
        if gemNum == #info then
            num = num + 1
            icon = GetIconFrame(frame)
            icon.title = L.BeltBuckle
            icon.bg:SetVertexColor(1, 0.2, 0.2, 0.6)
            icon.texture:SetTexture("Interface\\Cursor\\Quest")
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", anchorFrame, "RIGHT", num == 1 and 6 or 1, 0)
            icon:Show()
            anchorFrame = icon
        end
    end
    if ns.IsClassicSoD and LibItemEnchant:IsEquipmentSlotEngravable(itemframe.index) then
        num = num + 1
        icon = GetIconFrame(frame)
        local runeName, runeSpellID = LibItemEnchant:GetRuneInfo(unit, itemframe.index)
        if runeName then
            _, _, texture = GetSpellInfo(runeSpellID)
            icon.bg:SetVertexColor(0.64, 0.2, 0.93, 1)
            icon.texture:SetTexture(texture)
            UpdateIconTexture(icon, texture, runeSpellID, "spell")
            icon.spellID = runeSpellID
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", anchorFrame, "RIGHT", num == 1 and 6 or 1, 0)
            icon:Show()
            anchorFrame = icon
        else
            icon.title = RUNES
            icon.bg:SetVertexColor(1, 0.2, 0.2, 0.6)
            icon.texture:SetTexture("Interface\\Cursor\\UnableQuest")
            icon:ClearAllPoints()
            icon:SetPoint("LEFT", anchorFrame, "RIGHT", num == 1 and 6 or 1, 0)
            icon:Show()
            anchorFrame = icon
        end
    end
    return num * 18
end

--功能附着
hooksecurefunc("ShowInspectItemListFrame", function(unit, parent, itemLevel, maxLevel)
    local frame = parent.inspectFrame
    if (not frame) then return end
    local i = 1
    local itemframe
    local width, iconWidth = frame:GetWidth(), 0
    HideAllIconFrame(frame)
    while (frame["item"..i]) do
        itemframe = frame["item"..i]
        iconWidth = ShowGemAndEnchant(frame, itemframe.link, itemframe.itemString, itemframe, unit)
        if (width < itemframe.width + iconWidth + 36) then
            width = itemframe.width + iconWidth + 36
        end
        i = i + 1
    end
    if (width > frame:GetWidth()) then
        frame:SetWidth(width)
    end
end)
