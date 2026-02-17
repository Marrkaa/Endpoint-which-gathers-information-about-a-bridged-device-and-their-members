local FunctionService = require("api/FunctionService")
local ubus = require("ubus")
local uci = require("uci").cursor()

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

function Service:GET_TYPE_table()
	local handle = io.popen("ip -json route show table all")
	local result = handle:read("*a")
	handle:close()

	local json = require("luci.jsonc")
	local routes = json.parse(result)

	return self:ResponseOK({
		routes = routes
	})
end

function Service:SetBridge()

	local data = self.arguments.data
	local name = data.name

	if not name then
		self:add_error(400, "Bridge name not specified", "name")
		return
	end

	if not uci:get("network", name) then
		self:add_critical_error(
			404,
			"Bridge UCI section not found. Use UCI section name (example: br_lan).",
			"name"
		)
		return
	end

	if data.mtu then
		uci:set("network", name, "mtu", tostring(data.mtu))
	end

	if data.macaddr then
		uci:set("network", name, "macaddr", data.macaddr)
	end

	if data.new_name then
		local old_device_name = uci:get("network", name, "name")

		if old_device_name and old_device_name ~= data.new_name then
			uci:set("network", name, "name", data.new_name)

			uci:foreach("network", "interface", function(s)
				if s.device == old_device_name then
					uci:set("network", s[".name"], "device", data.new_name)
				end
			end)
		end
	end

	uci:commit("network")

	local conn = ubus.connect()
	if not conn then
		self:add_error(500, "Can not connect to UBUS")
		conn:close()
	end

	conn:call("network", "reload", {});
	conn:close()

	return self:ResponseOK(
	{
		message = "Bridge configuration updated successfully"
	})
end


local set_action = Service:action("set", Service.SetBridge)

local name = set_action:option("name")
name.require = true
name.maxlength = 32

local mtu = set_action:option("mtu")
function mtu:validate(value)
	local num = tonumber(value)
	if not num or num < 576 or num > 9000 then
		return false, "Invalid MTU value"
	end
	return true
end

local macaddr = set_action:option("macaddr")
function macaddr:validate(value)
	if not string.match(value, "^%x%x:%x%x:%x%x:%x%x:%x%x:%x%x$") then
		return false, "Invalid MAC address format"
	end
	return true
end

local new_name = set_action:option("new_name")
new_name.maxlength = 32

return Service