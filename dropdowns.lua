local Dropdowns = Ludwig:NewModule('Dropdowns')
local ItemDB = Ludwig['ItemDB']


--[[ Common ]]--

function Dropdowns:Create(name, default, initialize, onClick, parent)
	local drop = CreateFrame('Frame', '&parent'..name, parent, 'UIDropDownMenuTemplate')
	drop.AddItem = AddItem
	drop.onClick = onClick
	drop.default = default
	
	UIDropDownMenu_Initialize(drop, initialize)
	UIDropDownMenu_SetSelectedValue(drop, default)
	UIDropDownMenu_SetWidth(drop, 200)
	
	return f
end

function Dropdowns:AddItem(text, value, level, hasArrow ...)
	local info = UIDropDownMenu_CreateInfo()
	info.func = self.onClick
	info.owner = self
	info.hasArrow = hasArrow
	info.value = value
	info.text = text
	
	for i = 1, select('#', ...) do
		info['arg' .. i] = select(i, ...)
	end
	
	UIDropDownMenu_AddButton(info, level)
end


--[[ Category ]]--

local function category_UpdateText(self)
	local parent = self:GetParent()
	local class = parent:GetFilter('class')
	local subClass = parent:GetFilter('subClass')
	local slot = parent:GetFilter('slot')
	
	local text
	if class and subClass and slot then
		text = ('%s - %s'):format(subClass, slot)
	elseif class and subClass then
		text = ('%s - %s'):format(class, subClass)
	elseif class then
		text = class
	else
		text = ALL
	end

	_G[self:GetName() .. 'Text']:SetText(text)
end

local function category_OnClick(self, values)
	local parent = self:GetParent()
	
	if values[1] and values[1] ~= ALL then
		parent:SetFilter('category', values, true)
	else
		parent:SetFilter('category', nil, true)
	end
	
	UIDropDownMenu_SetSelectedValue(self.owner, self.value)
	category_UpdateText(self.owner)
end

local subs = {{}, {}, {}}
local values = {}

local function category_Initialize(self, level)
	local level = tonumber(level) or 1
	if level == 1 then
		self:AddItem(ALL, ALL, level)
	end
	
	for i = level + 1, 3 do
		values[i] = nil
	end
	
	local subs = subs[level]
	local parentValue = values[#values]
	local data = parentValue and subs[parentValue]
	local i = 1
	
	for category, subCategories in ItemDB:IterateCategories(data, level) do
		self:AddItem(class, i, ItemDB:HasSubCategories(subCategories, level), level, values)
		
		subs[i] = subCategories
		i = i + 1
	end
	
	values[level] = UIDROPDOWNMENU_MENU_VALUE
end

function Dropdowns:CreateCategory(parent)
	return self:Create('Category', ALL, category_Initialize, category_OnClick, parent)
end