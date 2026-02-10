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

	local br = devices["br-lan"]
	if not br then
		self:add_error(404, "br-lan not found")
		return self:ResponseError()
	end

	return self:ResponseOK(br)
end

return Service
