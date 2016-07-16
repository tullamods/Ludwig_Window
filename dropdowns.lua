local Dropdowns = Ludwig:NewModule('Dropdowns')
local ItemDB = Ludwig('ItemDB')


--[[ Common ]]--

function Dropdowns:Create(name, width, initialize, click, update, parent)
	local drop = CreateFrame('Frame', '$parent'..name, parent, 'UIDropDownMenuTemplate')
    drop.UpdateText = self.UpdateText
    drop.AddItem = self.AddItem
    drop.OnClick = self.OnClick

    drop.update = update
    drop.click = click

	UIDropDownMenu_Initialize(drop, initialize)
	UIDropDownMenu_SetWidth(drop, width)

	drop:UpdateText()
	return drop
end

function Dropdowns:UpdateText()
    _G[self:GetName() .. 'Text']:SetText(self:update())
end

function Dropdowns:AddItem(text, value, checked, arrow)
    return UIDropDownMenu_AddButton({
        func = self.OnClick,
        checked = checked,
        hasArrow = arrow,
        text = text,
        arg1 = self,
        arg2 = value,
        value = value
    }, UIDROPDOWNMENU_MENU_LEVEL)
end

function Dropdowns:OnClick(self, ...)
    self:click(...)
    self:UpdateText()
    CloseDropDownMenus()
end


--[[ Category ]]--

local function category_UpdateText(self)
    local filters = self:GetParent():GetFilter('category')
    if filters then
        local classes = Ludwig_Classes
        for l = 1, #filters-1 do
            classes = classes[filters[l]][2]
        end

        local class = classes[filters[#filters]]
        return type(class) == 'table' and class[1] or class
     else
        return ALL
    end
end

local function category_Select(self, values)
    self:GetParent():SetFilter('category', values, true)
end

local function category_Compare(a, b)
    if a and b and #a == #b then
        for l = 1, #a do
            if a[l] ~= b[l] then
                return
            end
        end

        return true
    end
end

local function category_Initialize(self, level)
    if not level then
        return
    end

    local filters = self:GetParent():GetFilter('category')
    local args = UIDROPDOWNMENU_MENU_VALUE or {}

    if level == 1 then
        self:AddItem(ALL, nil, not filters)
    end

    local classes = Ludwig_Classes
    for l = 1, level-1 do
        classes = classes[args[l]][2]
    end

    for i, class in pairs(classes) do
        local hasSubs = type(class) == 'table'
        local name = hasSubs and class[1] or class
        local value = {unpack(args)}
        value[level] = i

        self:AddItem(name, value, category_Compare(filters, value), hasSubs)
    end
end

function Dropdowns:CreateCategory(parent)
	return self:Create('Category', 200, category_Initialize, category_Select, category_UpdateText, parent)
end


--[[ Quality ]]--

local function quality_UpdateText(self)
	local quality = self:GetParent():GetFilter('quality') or -1
	if quality ~= -1 then
		local color = ITEM_QUALITY_COLORS[tonumber(quality)]
		return color.hex .. _G[('ITEM_QUALITY%s_DESC'):format(quality)] .. '|r'
	else
		return ALL
	end
end

local function quality_Select(self, i)
  self:GetParent():SetFilter('quality', i > -1 and i, true)
end

local function quality_Initialize(self)
	local quality = tonumber(self:GetParent():GetFilter('quality'))
    self:AddItem(ALL, -1, not quality)

	for i = 0, #ITEM_QUALITY_COLORS do
		local color = ITEM_QUALITY_COLORS[i]
		local text = color.hex .. _G[('ITEM_QUALITY%d_DESC'):format(i)] .. '|r'
        self:AddItem(text, i, quality == i)
	end
end

function Dropdowns:CreateQuality(parent)
	return self:Create('Quality', 90, quality_Initialize, quality_Select, quality_UpdateText, parent)
end