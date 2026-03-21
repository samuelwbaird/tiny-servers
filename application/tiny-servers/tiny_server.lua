local class = require('core.class')
local array = require('core.array')
local cache = require('core.cache')

local lfs = require('lfs')

-- regularly close/clean the DB? or open it in its most naive and editable formatlocal class = require('core.class')
return class(function (tiny_server)

	function tiny_server:init(server_name, path)
		log(server_name, '<reload>')
		self.server_name = server_name
		self.path = path
		self.lua_files = {}
		self.fresh = true
		
		-- scan and load all the lua files
		self:scan_lua_files('', function (filepath, attributes)
			local file = io.open(self.path .. filepath, 'rb')
			local contents = file:read('*a')
			file:close()
			self.lua_files[filepath] = {
				contents = contents,
				attributes = attributes,
			}
		end)
	end
	
	function tiny_server:handle_api(api_name, input)
		log(self.server_name, api_name)
		-- error('something went wrong')
		return self.server_name .. ' ' .. api_name
	end
	
	function tiny_server:check_if_fresh()
		if not self.fresh then
			return false
		end
		
		-- check if any of the files have changed (might need to cache this result later)
		self:scan_lua_files('', function (filepath, attributes)
			if self.lua_files[filepath] then
				if self.lua_files[filepath].attributes.modification ~= attributes.modification then
					self.fresh = false
				end
			else
				self.fresh = false
			end
		end)
		return self.fresh
	end
	
	function tiny_server:scan_lua_files(prefix, callback)
		for file in lfs.dir(self.path .. prefix) do
			if file:sub(1, 1) == '.' then
				-- skip .
			else
				local attributes = lfs.attributes(self.path .. prefix .. file)
				if attributes.mode == 'directory' then
					self:scan_lua_files(prefix .. file .. '/', callback)
				else
					-- if this is a lua file then 
					if file:match('%.lua$') then
						callback(prefix .. file, attributes)
					end
				end
			end
		end
	end

end)