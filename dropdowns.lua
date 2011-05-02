local Dropdowns = Ludwig:NewModule('Dropdowns')


--[[ Common ]]--

function Dropdowns:Create(name, default, initialize, addItem, parent)
	local drop = CreateFrame('Frame', '&parent'..name, parent, 'UIDropDownMenuTemplate')
	drop.addItem = addItem
	drop.default = default
	
	UIDropDownMenu_Initialize(drop, initialize)
	UIDropDownMenu_SetSelectedValue(drop, default)
	UIDropDownMenu_SetWidth(drop, 200)
	
	return f
end

function Dropdowns:AddItem(func, text, value, level ...)
	local info = UIDropDownMenu_CreateInfo()
	info.owner = self
	info.text = text
	info.value = value
	info.func = func
	
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

local function category_OnClick(self, class, subClass)
	local selectedClass, selectedSubClass, selectedSlot
	local parent = self:GetParent()
	
	if class and subClass then
		selectedClass = class
		selectedSubClass = subClass
		selectedSlot = self.value
	elseif class then
		selectedClass = class
		selectedSubClass = self.value
	elseif self.value ~= ALL then
		selectedClass = self.value
	end

	parent:SetFilter('class', selectedClass)
	parent:SetFilter('subClass', selectedSubClass)
	parent:SetFilter('slot', selectedSlot, true)
	
	UIDropDownMenu_SetSelectedValue(self.owner, self.value)
	category_UpdateText(self.owner)
end

local selectedClass = nil
local function category_Initialize(self, level)
	local level = tonumber(level) or 1
	if level == 1 then
		self:addItem(level, ALL, ALL, ALL)
		for class, subClasses in Ludwig('ItemDB'):IterateClasses() do
			local hasArrow = false
			for subClass, slots in Ludwig('ItemDB'):IterateSubClasses(subClasses) do
				hasArrow = true
				break
			end
			
			local item = self:createItem(class, class)
			item.hasArrow = hasArrow
			UIDropDownMenu_AddButton(item, level)
		end
	elseif level == 2 then
		selectedClass = _G['UIDROPDOWNMENU_MENU_VALUE']
		for class, subClasses in Ludwig('ItemDB'):IterateClasses() do
			if class == selectedClass then
				for subClass, slots in Ludwig('ItemDB'):IterateSubClasses(subClasses) do
					local hasArrow = false
					for slot in Ludwig('ItemDB'):IterateSlots(slots) do
						hasArrow = true
						break
					end
					
					local item = self:createItem(subClass, subClass, class)
					item.hasArrow = hasArrow
					UIDropDownMenu_AddButton(item, level)
				end
				break
			end
		end
	elseif level == 3 then
		local selectedSubClass = _G['UIDROPDOWNMENU_MENU_VALUE']
		for class, subClasses in Ludwig('ItemDB'):IterateClasses() do
			if class == selectedClass then
				for subClass, slots in Ludwig('ItemDB'):IterateSubClasses(subClasses) do
					if subClass == selectedSubClass then
						for slot in Ludwig('ItemDB'):IterateSlots(slots) do
							self:addItem(level, slot, slot, class, subClass)
						end
						break
					end
				end
				break
			end
		end
	end
end

local function category_AddItem(self, ...)
	return Dropdowns.AddItem(self, typeFilter_OnClick, ...)
end

function Dropdowns:CreateCategory(parent)
	return self:Create('Category', ALL, category_Initialize, category_AddItem, parent)
end