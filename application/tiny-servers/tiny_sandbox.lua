local class = require('core.class')

return class(function (tiny_sandbox)

	local prelude = nil

	function tiny_sandbox:init()
		self.environment = {
			-- lua modules
			string = string,
			table = table,
			math = math,
			
			-- lua global functions
			pairs = pairs,
			ipairs = ipairs,
			type = type,
			print = print,
			error = error,
			tostring = tostring,
			tonumber = tonumber,
			getmetatable = getmetatable,
			setmetatable = setmetatable,
		}
		self.environment['_ENV'] = self.environment
		self.environment['_G'] = self.environment
		
		-- add the support libs to the sandbox
		if not prelude then
			local file = io.open('submodules/prelude/prelude.lua', 'rb')
			prelude = file:read('*a')
			file:close()
		end
		
		-- execute as module
		self.environment.prelude = self:execute_code(prelude, 'prelude')
		
		-- finalise 
		self:execute_code('prelude.global().strict()', 'prelude_final')
	end
	
	function tiny_sandbox:execute_code(code, name)
		if setfenv then
			local chunk, compile_error = loadstring(code, name)
			if not chunk then
				error(compile_error)
			end
			setfenv(chunk, self.environment)
			return chunk()
		else
			local chunk, compile_error = load(code, name, 't', self.environment)
			if not chunk then
				error(compile_error)
			end
			return chunk()
		end
		
	end
	
	function tiny_sandbox:execute_file(filepath, name)
		local file = assert(io.open(filepath, 'rb'), 'could not read script ' .. filepath)
		local code = file:read('*a')
		file:close()
		return self:execute_code(code, name or filepath)
	end
	
	function tiny_sandbox:function_exists(function_name)
		return type(rawget(self.environment, function_name)) == 'function'
	end
	
	function tiny_sandbox:execute_function(function_name, ...)
		return self.environment[function_name](...)
	end

end)