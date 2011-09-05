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

function Dropdowns:AddItem(text, value, checked)
  return {
    func = self.OnClick,
    checked = checked,
    text = text,
    arg1 = self,
    arg2 = value
  }
end

function Dropdowns:OnClick(self, ...)
  self:click(...)
  self:UpdateText()
  CloseDropDownMenus()
end


--[[ Category ]]--

local function category_UpdateText(self)
  local level = self.names and #self.names or 0
  if level > 0 then
    if level > 1 then
      return ('%s - %s'):format(self.names[2], self.names[1])
    else
      return self.names[1]
    end
  else
    return ALL
  end
end

local function category_Select(self, values)
  local filter = {}
  local names = {}

  if values then
    for i = #values - 1, 1, -2 do
      tinsert(filter, values[i])
    end
    
    for i = 2, #values, 2 do
      tinsert(names, values[i])
    end
  end

  self:GetParent():SetFilter('category', values and filter, true)
  self.names = names
end

local function category_BuildList(self, filters, list, level, source, ...)
  local i = 1

  for name, subs in ItemDB:IterateCategories(source, level) do
    local values = {i, name, ...}
    local total = #values
    local checked = filters

    if checked then
      for i = 1, total, 2 do
        if filters[(total + 1 - i) / 2] ~= values[i] then
          checked = nil
          break
        end
      end
    end
    
    local item = self:AddItem(name, values, checked)
    if ItemDB:HasSubCategories(subs, level) then
      item.menuList = {}
      item.hasArrow = true
  
      category_BuildList(self, filters, item.menuList, level + 1, subs, i, name, ...)
    end

    list[i] = item
    i = i + 1
  end

  return list
end

local function category_Initialize(self, level, list)
  local filters = self:GetParent():GetFilter('category')

  if not list then
    list = category_BuildList(self, filters, {}, 1)
    tinsert(list, 1, self:AddItem(ALL, nil, not filters))
  end

  EasyMenu_Initialize(self, level, list)
  collectgarbage()
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
  self:GetParent():SetFilter('quality', i > -1 and tostring(i), true)
end

local function quality_AddItem(self, ...)
  UIDropDownMenu_AddButton(self:AddItem(...))
end

local function quality_Initialize(self)
	local quality = tonumber(self:GetParent():GetFilter('quality'))
  quality_AddItem(self, ALL, -1, not quality)

	for i = 0, #ITEM_QUALITY_COLORS do
		local color = ITEM_QUALITY_COLORS[i]
		local text = color.hex .. _G[('ITEM_QUALITY%d_DESC'):format(i)] .. '|r'

   quality_AddItem(self, text, i, quality == i)
	end
end

function Dropdowns:CreateQuality(parent)
	return self:Create('Quality', 90, quality_Initialize, quality_Select, quality_UpdateText, parent)
end