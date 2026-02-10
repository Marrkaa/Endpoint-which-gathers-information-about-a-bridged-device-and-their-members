local FunctionService = require("api/FunctionService")
local ubus = require("ubus")

local Service = FunctionService:new()

function Service:GET_TYPE_bridge()
	local conn = ubus.connect()
	if not conn then
		self:add_critical_error(500, "Cannot connect to ubus")
		return self:ResponseError()
	end

	local devices = conn:call("network.device", "status", {})
	conn:close()

	local bridges = {}

	for devname, dev in pairs(devices) do
		if dev.devtype == "bridge" then
			local members = {}

			for _, ifname in ipairs(dev["bridge-members"] or {}) do
				local m = devices[ifname]
				if m then
					table.insert(members, {
						name = ifname,
						type = m.devtype,
						up = m.up,
						carrier = m.carrier,
						macaddr = m.macaddr
					})
				end
			end

			table.insert(bridges, {
				name = devname,
				type = dev.devtype,
				up = dev.up,
				mtu = dev.mtu,
				macaddr = dev.macaddr,
				members = members
			})
		end
	end

	if #bridges == 0 then
		self:add_error(404, "No bridge devices found")
		return self:ResponseError()
	end

	return self:ResponseOK({
		bridges = bridges
	})
end

return Service
