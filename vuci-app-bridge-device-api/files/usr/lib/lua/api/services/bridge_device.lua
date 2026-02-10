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

function Service:POST_TYPE_set()
	local data = self.arguments.data
	local name = data.name	

	if not name then
		self:add_error(400, "Bridge name not specified", "name")
		return self:ResponseError()
	end

	if data.mtu then
		os.execute(string.format("ip link set dev %s mtu %d", name, tonumber(data.mtu)))
	end

	if data.macaddr then
		os.execute(string.format("ip link set dev %s address %s", name, data.macaddr))
	end

	if data.new_name then
		os.execute(string.format("ip link set dev %s name %s", name, data.new_name))
	end

	return self:ResponseOK(
	{
		message = "Bridge parameters updated (runtime)",
		bridge = name
	})
end

return Service
