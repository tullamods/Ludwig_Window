local Dropdowns = Ludwig:NewModule('Dropdowns')
local ItemDB = Ludwig['ItemDB']


--[[ Common ]]--

function Dropdowns:Create(name, width, default, initialize, onClick, updateText, parent)
	local drop = CreateFrame('Frame', '&parent'..name, parent, 'UIDropDownMenuTemplate')
	drop.ClickItem = self.ClickItem
	drop.AddItem = self.AddItem
	drop.UpdateText = updateText
	drop.onClick = onClick
	drop.default = default
	
	UIDropDownMenu_Initialize(drop, initialize)
	UIDropDownMenu_SetWidth(drop, width)
	
	drop:UpdateText()
	return drop
end

function Dropdowns:AddItem(text, value, checked, level, hasArrow, ...)
	local info = UIDropDownMenu_CreateInfo()
	info.func = self.ClickItem
	info.hasArrow = hasArrow
	info.checked = checked
	info.value = value
	info.text = text
	info.owner = self
	
	for i = 1, select('#', ...) do
		info['arg' .. i] = select(i, ...)
	end
	
	UIDropDownMenu_AddButton(info, level)
end

function Dropdowns:ClickItem(...)
	self.owner.onClick(self, ...)
	self.owner:UpdateText()
end


--[[ Category ]]--

local subs = {{}, {}, {}}
local selections = {}

local function category_UpdateText(self)
	local parent = self:GetParent()
	local category = parent:GetFilter('category')
	local text
	
	if category then
		if #category > 1 then
			text = ('%s - %s'):format(category[#category - 1], category[#category])
		else
			text = category[1]
		end
	else
		text = ALL
	end

	_G[self:GetName() .. 'Text']:SetText(text)
end

local function category_OnClick(self, level)
	local parent = self.owner:GetParent()
	
	if self.value ~= ALL then
		local category = CopyTable(selections)
		category[level] = self.value
		
		parent:SetFilter('category', category, true)
	else
		parent:SetFilter('category', nil, true)
	end
end

local function category_Initialize(self, level)
	local category = self:GetParent():GetFilter('category')
	local level = tonumber(level) or 1
	if level == 1 then
		self:AddItem(ALL, ALL, not category)
	end
	
	local parentID = UIDROPDOWNMENU_MENU_VALUE
	local parentChecked = category
	local parentLevel = level - 1
	
	selections[parentLevel] = parentID
	for i = level, 3 do
		selections[i] = nil
	end
	
	if category then
		for i = 1, parentLevel do
			if category[i] ~= selections[i] then
				parentChecked = nil
				break
			end
		end
	end
	
	local data = parentID and subs[parentLevel][parentID]
	local current = parentChecked and category[level]
	local subs = subs[level]
	local i = 1
	
	for category, subCategories in ItemDB:IterateCategories(data, level) do
		self:AddItem(category, i, i == current, level, ItemDB:HasSubCategories(subCategories, level), level)
		
		subs[i] = subCategories
		i = i + 1
	end
end

function Dropdowns:CreateCategory(parent)
	return self:Create('Category', 200, ALL, category_Initialize, category_OnClick, category_UpdateText, parent)
end


--[[ Quality ]]--

local function quality_UpdateText(self)
	local quality = self:GetParent():GetFilter('quality') or -1
	if quality ~= -1 then
		local color = ITEM_QUALITY_COLORS[tonumber(quality)]
		local text = color.hex .. _G[('ITEM_QUALITY%s_DESC'):format(quality)] .. '|r'
		_G[self:GetName() .. 'Text']:SetText(text)
	else
		_G[self:GetName() .. 'Text']:SetText(ALL)
	end
end

local function quality_OnClick(self)
	self.owner:GetParent():SetFilter('quality', self.value > -1 and tostring(self.value), true)
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
	return self:Create('Quality', 90, -1, quality_Initialize, quality_OnClick, quality_UpdateText, parent)
end