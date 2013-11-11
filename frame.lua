local Ludwig = _G['Ludwig']
local Frame = Ludwig:NewModule('Frame', CreateFrame('Frame', 'LudwigFrame', UIParent))
local filters, results, numResults = {}

local ItemDB = Ludwig('ItemDB')
local L = Ludwig('Locals')

local ITEMS_TO_DISPLAY = 15
local ITEM_STEP = 22


--[[ Startup ]]--

function Frame:Startup()
	self:Hide()

	local Dropdowns = Ludwig('Dropdowns')
	local Editboxes = Ludwig('Editboxes')
	local Others = Ludwig('Others')

	--set attributes
	self:SetScript('OnShow', self.OnShow)
	self:SetScript('OnHide', self.OnHide)
	self.Startup = nil
	
	self:SetHitRectInsets(0, 35, 0, 75)
	self:SetSize(384, 512)
	self:EnableMouse(true)

	self:SetAttribute('UIPanelLayout-defined', true)
	self:SetAttribute('UIPanelLayout-enabled', true)
	self:SetAttribute('UIPanelLayout-whileDead', true)
	self:SetAttribute('UIPanelLayout-area', 'left')
	self:SetAttribute('UIPanelLayout-pushable', 1)
	self:SetAttribute('UIPanelLayout-xoffset', 200)
	table.insert(UISpecialFrames, self:GetName())

	--icon
	local icon = self:CreateTexture(nil, 'BACKGROUND')
	icon:SetSize(62, 62)
	icon:SetPoint('TOPLEFT', 5, -5)
	SetPortraitToTexture(icon, [[Interface\Icons\INV_Misc_Book_04]])

	--background textures
	local tl = self:CreateTexture(nil, 'ARTWORK')
	tl:SetSize(256, 256)
	tl:SetPoint('TOPLEFT')
	tl:SetTexture([[Interface\TaxiFrame\UI-TaxiFrame-TopLeft]])

	local tr = self:CreateTexture(nil, 'ARTWORK')
	tr:SetSize(128, 256)
	tr:SetPoint('TOPRIGHT')
	tr:SetTexture([[Interface\TaxiFrame\UI-TaxiFrame-TopRight]])

	local bl = self:CreateTexture(nil, 'ARTWORK')
	bl:SetSize(256, 256)
	bl:SetPoint('BOTTOMLEFT')
	bl:SetTexture([[Interface\PaperDollInfoFrame\SkillFrame-BotLeft]])

	local br = self:CreateTexture(nil, 'ARTWORK')
	br:SetSize(128, 256)
	br:SetPoint('BOTTOMRIGHT')
	br:SetTexture([[Interface\PaperDollInfoFrame\SkillFrame-BotRight]])

	--add title text
	local title = self:CreateFontString('$parentTitle', 'ARTWORK', 'GameFontHighlight')
	title:SetSize(300, 14)
	title:SetPoint('TOP', 0, -16)
	self.title = title

	--close button
	local closeButton = CreateFrame('Button', '$parentCloseButton', self, 'UIPanelCloseButton')
	closeButton:SetPoint('TOPRIGHT', -29, -8)

	--search box
	local search = Editboxes:CreateSearch(self)
	search:SetPoint('TOPLEFT', 84, -44)
	self.search = search

	--level search
	local minLevel = Editboxes:CreateMinLevel(self)
	minLevel:SetPoint('LEFT', search, 'RIGHT', 12, 0)
	self.minLevel = minLevel

	local hyphenText = self:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightSmall')
	hyphenText:SetText('-')
	hyphenText:SetPoint('LEFT', minLevel, 'RIGHT', 1, 0)

	local maxLevel = Editboxes:CreateMaxLevel(self)
	maxLevel:SetPoint('LEFT', minLevel, 'RIGHT', 12, 0)
	self.maxLevel = maxLevel

	--reset button
	local resetButton = Others:CreateResetButton(self)
	resetButton:SetPoint('LEFT', maxLevel, 'RIGHT', -2, -2)

	--scroll area
	local scrollFrame = Others:CreateScrollFrame(self)
	scrollFrame:SetPoint('TOPLEFT', 24, -78)
	scrollFrame:SetPoint('BOTTOMRIGHT', -68, 106)
	self.scrollFrame = scrollFrame

	--quality filter
	local quality = Dropdowns:CreateQuality(self)
	quality:SetPoint('BOTTOMLEFT', 0, 72)
	self.quality = quality

	--category filter
	local category = Dropdowns:CreateCategory(self)
	category:SetPoint('BOTTOMLEFT', 110, 72)
	self.category = category

	--item buttons
	local items = {}
	for i = 1, ITEMS_TO_DISPLAY do
		local item = Others:CreateItemButton(self, i)
		item:SetPoint('TOPLEFT', scrollFrame, 'TOPLEFT', 0, -item:GetHeight() * (i-1))
		items[i] = item
	end
	self.itemButtons = items
	
	-- clean modules
	wipe(Dropdowns)
	wipe(Editboxes)
	wipe(Others)
end


--[[ Toggle ]]--

function Frame:Toggle()
	if self:IsShown() then
		HideUIPanel(self)
	else
		ShowUIPanel(self)
	end
end

function Frame:OnShow()
	PlaySound('igCharacterInfoOpen')
	self:Update(true)
end

function Frame:OnHide()
	PlaySound('igCharacterInfoClose')
	results, numResults = nil
	collectgarbage() -- it's important to keep our trash clean. We don't want to attract rats, do we?
end



--[[ Update ]]--

function Frame:ScheduleUpdate()
	self.timer = 0.4
	self:SetScript('OnUpdate', self.DelayUpdate)
end

function Frame:DelayUpdate(elapsed)
	if self.timer > 0 then
		self.timer = self.timer - elapsed
	else
		self:SetScript('OnUpdate', nil)
		self:Update(true)
	end
end

function Frame:Update(search)
	if not results or search then
		results, numResults = ItemDB:GetItems(
			filters.search,
			filters.category,
			filters.minLevel,
			filters.maxLevel,
			filters.quality
		)
		
		self.title:SetText(L.FrameTitle:format(numResults))
	end

	local scrollFrame = self.scrollFrame
	local offset = FauxScrollFrame_GetOffset(scrollFrame) or 0
	local buttons = self.itemButtons
	
	for i = 1, ITEMS_TO_DISPLAY do
		local index = i + offset
		local button = buttons[i]
		
		if index > numResults then
			button:Hide()
		else
			local id, name, quality = ItemDB:GetItem(results, index)
			button.icon:SetTexture(GetItemIcon(id))
			button:SetFormattedText('%s%s|r', quality, name)
			button.quality = quality
			button.name = name
			button:SetID(id)
			button:Show()
		end
	end

	FauxScrollFrame_Update(
		scrollFrame,
		numResults,
		ITEMS_TO_DISPLAY,
		ITEM_STEP,
		self:GetName() .. 'Item',
		300,
		320,
		nil,
		nil,
		nil,
		false
	)
end


--[[ Filters ]]--

function Frame:SetFilter(index, value, force)
	if filters[index] ~= value then
		filters[index] = value

		if force then
			self:Update(true)
		else
			self:ScheduleUpdate()
		end
	end
end

function Frame:GetFilter(index)
	return filters[index]
end

function Frame:ClearFilters()
	local name = self:GetName()
	wipe(filters)
	
	self.search:GoDefault()
	self.minLevel:GoDefault()
	self.maxLevel:GoDefault()
	
	self.category:UpdateText()
	self.quality:UpdateText()

	self:Update(true)
end

Frame:Startup()