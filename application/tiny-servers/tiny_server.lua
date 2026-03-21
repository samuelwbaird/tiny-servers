local lfs = require('lfs')

local class = require('core.class')
local array = require('core.array')
local cache = require('core.cache')

local tiny_sandbox = require('tiny-servers.tiny_sandbox')

-- regularly close/clean the DB? or open it in its most naive and editable formatlocal class = require('core.class')
return class(function (tiny_server)

	function tiny_server:init(server_name, path)
		log(server_name, '<reload>')
		self.server_name = server_name
		self.path = path
		self.lua_files = {}
		self.fresh = true
		
		-- prepare the sandbox environment for this code
		self.sandbox = tiny_sandbox()
		
		-- scan and load all the lua files
		self:scan_lua_files('', function (filepath, attributes)
			local file = io.open(self.path .. filepath, 'rb')
			local contents = file:read('*a')
			file:close()
			self.lua_files[filepath] = {
				contents = contents,
				attributes = attributes,
			}
			self.sandbox:execute_file(self.path .. filepath, server_name .. '/' .. filepath)
		end)
	end
	
	function tiny_server:handle_api(api_name, input)
		local function_name = 'api_' .. api_name
		if not self.sandbox:function_exists(function_name) then
			error(self.server_name .. ': api function does not exist ' .. function_name)
		end
		-- find the session object (if it exists)
		local session = {}
		return self.sandbox:execute_function('api_' .. api_name, session, input)
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
		-- always process files in a set order, alphabetical, files before folders
		local files = {}
		for file in lfs.dir(self.path .. prefix) do
			if file:sub(1, 1) == '.' then
				-- skip .
			else
				files[#files + 1] = file
			end
		end
		table.sort(files)
		
		local folders= {}
		for _, file in ipairs(files) do
			local attributes = lfs.attributes(self.path .. prefix .. file)
			if attributes.mode == 'directory' then
				folders[#folders + 1] = file
			elseif file:match('%.lua$') then
				-- if this is a lua file then 
				callback(prefix .. file, attributes)
			end
		end
		for _, folder in ipairs(folders) do
			self:scan_lua_files(prefix .. folder .. '/', callback)
		end
	end

end)