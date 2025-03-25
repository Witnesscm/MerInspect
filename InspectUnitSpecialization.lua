---------------------------------------
-- 顯示職業圖標和天赋
-- @Author: M
-- @DepandsOn: InspectUnit.lua
---------------------------------------
local addon, ns = ...

local LibEvent = LibStub:GetLibrary("LibEvent.7000")

local cache = {}

local function GetInspectTalentInfo(unit, isActiveTalent)
    if (not GetTalentTabInfo) then return end
    local isInspect = (unit ~= "player")
    local talentGroup = GetActiveTalentGroup(isInspect)

    if not isActiveTalent then
        if talentGroup == 1 then
            talentGroup = 2
        elseif talentGroup == 2 then
            talentGroup = 1
        end
    end

    local index
    local higher = 0
    for i = 1, 3 do
        cache[i] = {}

        local _, name, _, icon, point = GetTalentTabInfo(i, isInspect, false, talentGroup)

        if point > higher then
            higher = point
            index = i
        end

        cache[i].name = name
        cache[i].icon = icon
        cache[i].point = point
    end

    return index, cache
end

hooksecurefunc("ShowInspectItemListFrame", function(unit, parent, itemLevel, maxLevel)
    local frame = parent.inspectFrame
    if (not frame) then return end
    if (not frame.specicon) then
        frame.specicon = frame:CreateTexture(nil, "BORDER")
        frame.specicon:SetSize(42, 42)
        frame.specicon:SetPoint("TOPRIGHT", -10, -11)
        frame.specicon:SetAlpha(0.5)
        frame.specicon:SetMask("Interface\\Minimap\\UI-Minimap-Background")
        frame.classicon = frame:CreateTexture(nil, "BORDER")
        frame.classicon:SetSize(42, 42)
        frame.classicon:SetPoint("TOPRIGHT", -10, -11)
        frame.classicon:SetAlpha(0.5)
        frame.classicon:SetTexture("Interface\\TargetingFrame\\UI-Classes-Circles")
        frame.spectext = frame:CreateFontString(nil, "BORDER")
        frame.spectext:SetFont(SystemFont_Outline_Small:GetFont(), 11, "THINOUTLINE")
        frame.spectext:SetPoint("BOTTOM", frame.specicon, "BOTTOM", 0, -7)
        frame.spectext:SetJustifyH("CENTER")
        --frame.spectext:SetAlpha(0.9)
    end

    local index, talentCache = GetInspectTalentInfo(unit, true)
    local specIcon = index and talentCache[index].icon

    if specIcon then
        frame.spectext:SetText(index and format("|CFFFFD200%s|r\n\n%s/%s/%s", talentCache[index].name, talentCache[1].point, talentCache[2].point, talentCache[3].point) or format("%s/%s/%s", 0, 0, 0))
        frame.specicon:SetShown(not not specIcon)
        frame.classicon:SetShown(not specIcon)
        frame.specicon:SetTexture(specIcon)
    else
        local class = select(2, UnitClass(unit))
        local x1, x2, y1, y2 = unpack(CLASS_ICON_TCOORDS[strupper(class)])
        frame.classicon:SetTexCoord(x1, x2, y1, y2)
    end

    
    if (not frame.subspecicon) then
        frame.subspecicon = frame:CreateTexture(nil, "BORDER")
        frame.subspecicon:SetSize(21, 21)
        frame.subspecicon:SetPoint("TOPRIGHT", -72, -21)
        frame.subspecicon:SetAlpha(0.5)
        frame.subspecicon:SetMask("Interface\\Minimap\\UI-Minimap-Background")

        frame.subspectext = frame:CreateFontString(nil, "BORDER")
        frame.subspectext:SetFont(UNIT_NAME_FONT, 10, "THINOUTLINE")
        frame.subspectext:SetPoint("BOTTOM", frame.subspecicon, "BOTTOM", 0, -7)
        frame.subspectext:SetJustifyH("CENTER")
    end

    local index, talentCache = GetInspectTalentInfo(unit, false)
    local specIcon = index and talentCache[index].icon
    --如果有次天赋，显示次天赋名称和图标
    if specIcon then
        frame.subspectext:SetText(format("|CFF1EFF00次：%s|r", talentCache[index].name))
        frame.subspecicon:SetShown(specIcon)
        frame.subspecicon:SetTexture(specIcon)
    end
end)
