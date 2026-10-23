-- one tiny server, its lua files loaded into a sandbox, and reloaded whenever they change

local lfs = require('lfs')
local utc_time = require('rascal.messaging').utc_time

local tiny_sandbox = require('tiny-servers.tiny_sandbox')

local tiny_server = class()

function tiny_server:init(server_name, path)
	log(server_name, '<reload>')
	self.server_name = server_name
	self.path = path
	self.lua_files = {}
	self.fresh = true
	self.last_scan = utc_time()

	-- prepare the sandbox environment for this code
	self.sandbox = tiny_sandbox(self.server_name, self.path)

	-- scan and load all the lua files
	self:scan_lua_files('', function (filepath, attributes)
		self.lua_files[filepath] = {
			attributes = attributes,
		}
		self.sandbox:execute_file(self.path .. filepath, server_name .. '/' .. filepath)
	end)

	-- user provided prepare method if supplied
	if self.sandbox:function_exists('prepare') then
		self.sandbox:execute_function('prepare')
	end
end

function tiny_server:handle_api(api_name, session, input)
	local function_name = 'api_' .. api_name
	if not self.sandbox:function_exists(function_name) then
		error(self.server_name .. ': api function does not exist ' .. function_name)
	end
	return self.sandbox:execute_function(function_name, session, input)
end

function tiny_server:check_if_fresh()
	if not self.fresh then
		return false
	end

	-- its costly to scan all the files every time, so only recheck if the last scan
	-- was at least a small amount of time ago (keep this short, so debug cycle is responsive)
	local now = utc_time()
	if now - self.last_scan > 0.5 then
		self.last_scan = now
		-- check if any of the files have changed
		self:scan_lua_files('', function (filepath, attributes)
			if self.lua_files[filepath] then
				if self.lua_files[filepath].attributes.modification ~= attributes.modification then
					self.fresh = false
				end
			else
				self.fresh = false
			end
		end)
	end
	return self.fresh
end

function tiny_server:scan_lua_files(prefix, callback)
	-- always process files in a set order, alphabetical, files before folders
	local files = {}
	for file in lfs.dir(self.path .. prefix) do
		if file:sub(1, 1) ~= '.' then
			files[#files + 1] = file
		end
	end
	table.sort(files)

	local folders = {}
	for _, file in ipairs(files) do
		local attributes = lfs.attributes(self.path .. prefix .. file)
		if attributes.mode == 'directory' then
			folders[#folders + 1] = file
		elseif file:match('%.lua$') then
			callback(prefix .. file, attributes)
		end
	end
	for _, folder in ipairs(folders) do
		self:scan_lua_files(prefix .. folder .. '/', callback)
	end
end

return tiny_server
