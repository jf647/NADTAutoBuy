
NAB = LibStub("AceAddon-3.0"):NewAddon(
    "NADTAutoBuy",
    "AceConsole-3.0",
	"AceEvent-3.0"
)

buying_enabled = true

function NAB:OnEnable()

	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterChatCommand("nab", "SlashCommand")
	self:Print("NADTAutoBuy enabled")

end

function NAB:OnDisable()

	self:UnregisterAllEvents()
	self:UnregisterChatCommand("nab")
	self:Print("NADTAutoBuy disabled")

end

-- handle /nab slash command
-- /nab enable
-- /nab disable
-- /nab list
-- /nab buying
-- /nab what
function NAB:SlashCommand(text)
    local command, rest = text:match("^(%S*)%s*(.-)$")
    if command == "enable" then
        self:Enable()
    elseif command == "disable" then
        self:Disable()
    elseif command == "list" then
		self:ListAutoBuy()
    elseif command == "buying" then
		buying_enabled = not buying_enabled
		if buying_enabled then
			self:Print("buying is now enabled")
		else
			self:Print("buying is now disabled")
		end
    elseif command == "what" then
		self:ListWhat()
	else
        self:Print("usage: /nab enable")
        self:Print("       /nab disable")
        self:Print("       /nab list")
		self:Print("       /nab buying")
		self:Print("       /nab what")
    end
end

local lastMerchant = 0
function NAB:MERCHANT_SHOW()

	-- prevent firing too quickly
	if GetTime()<lastMerchant + 2 then return end
	lastMerchant = GetTime()

	-- find out what we're low on
	local needed = self:ListWhat()
	
	-- buy what we need
	for ic, tobuy in pairs( needed ) do
		for _, item in ipairs( NAB_DB.itemclasses[ic].items ) do
			if tobuy > 0 then
				local merchslot = self:FindItemOnMerchant(item)
				if merchslot then
					_, link, _, _, _, _, _, stackcount = GetItemInfo(item)
					_, _, _, _, available = GetMerchantItemInfo(merchslot)
					if -1 == available then available = tobuy end
					tobuy = min(tobuy, available)
					while tobuy > 0 do
						local this = min(tobuy, stackcount)
						self:Printf("buying %d of %s", this, link)
						if buying_enabled then BuyMerchantItem(merchslot, this) end
						tobuy = tobuy - this
					end
				end
			end
		end
	end

end

function NAB:FindItemOnMerchant(item)

	for i = 1, GetMerchantNumItems() do
		local link, id
		link = GetMerchantItemLink(i)
		if link then
			id = string.match(link, "item:(%d+):") + 0
			if id == item then return i end
		end
	end
	
	return

end

function NAB:ListAutoBuy()

	for ic, current in pairs( NAB_DB.itemclasses ) do
		self:Printf("ItemClass: %s (%d)", ic, current.quantity)
		local name
		for _, item in ipairs( current.items ) do
			name = GetItemInfo(item)
			if name then
				self:Printf(" - %s (%d)", name, item)
			else
				self:Printf(" - Unknown (%d)", item)
			end
		end
	end

end

function NAB:ListWhat()

	-- determine what we're low on
	local onhand
	local needed = {}
	for ic, current in pairs( NAB_DB.itemclasses ) do
		class_onhand = 0
		for _, item in ipairs( current.items ) do
			class_onhand = class_onhand + GetItemCount(item)
		end
		if class_onhand < current.quantity then
			needed[ic] = current.quantity - class_onhand
			self:Printf("need %d of %s (%d on hand, %d wanted)", needed[ic], ic, class_onhand, current.quantity)
		end
	end
	
	return needed

end