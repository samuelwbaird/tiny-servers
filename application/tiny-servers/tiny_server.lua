local class = require('core.class')
local array = require('core.array')
local cache = require('core.cache')

-- regularly close/clean the DB? or open it in its most naive and editable formatlocal class = require('core.class')
return class(function (tiny_server)

	function tiny_server:init(server_name, path)
		self.server_name = server_name
		self.path = path
		log('load ' .. server_name)
	end
	
	function tiny_server:handle_api(api_name, input)
		return {
			success = true,
			error = nil,
			message = self.server_name .. ' ' .. api_name,
			data = '',
		}
	end
	
	function tiny_server:check_if_fresh()
		return true
	end
	
	function tiny_server:slow_tick()
		-- call clean up tick on all servers
	end

end)