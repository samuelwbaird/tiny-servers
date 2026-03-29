local sql = require('lsqlite3')

local class = require('core.class') -- using rascal class to fit with other servers
local prelude = require('prelude')	-- using prelude list in results to fit with tiny-server sandbox

-- simplified use case database class

return class(function (database)
	
	-- load shared instance for any given path ----------------------------------------------------

	local open_databases = {}
	
	function database.for_filepath(filepath)
		if not open_databases[filepath] then
			open_databases[filepath] = database(filepath)
		end
		return open_databases[filepath]
	end
	
	function database:init(filepath)
		self.filepath = filepath
		self.sqlite = sql.open(filepath)
		self.prepared = {}
	end
	
	-- general purpose SQL query function with bindings ------------------------------------------
	
	function database:query(query, bindings)
		log('sql ' .. self.filepath, query)
		-- find memoised prepared statement
		if not self.prepared[query] then
			self.prepared[query] = assert(self.sqlite:prepare(query), 'prepare: ' .. query)
		end
		local statement = self.prepared[query]
		statement:reset()
		if bindings then
			assert(statement:bind_names(bindings) == sqlite3.OK)
		end
		return self:result(statement)
	end
	
	-- a wrapper for the results of any query ----- -----------------------------------------
	
	function database:result(statement)
		local result = {
			success = false,			-- did this query succeed
			row = nil,					-- the first or only row
			value = nil,				-- the first value of the first row (if present)
			has_rows = false,			-- does this query have rows
			num_rows = 0,				-- number of rows
			rows = prelude.list(),		-- all rows in the result
		}
		
		while true do
			local step = statement:step()
			if step == sqlite3.DONE then
				result.success = true
				break
			elseif step == sqlite3.ROW then
				result.rows:push(statement:get_named_values())
				if not result.value then
					result.value = statement:get_value(0)
				end
				result.has_rows = true
				result.num_rows = result.num_rows + 1
			else
				break
			end
		end
		
		return result
	end
	
	-- convenient versions of basic queries ---------------------- ------------------------------
	
	function database:select(table, id)
		return self:query('SELECT * FROM ' .. database.safe_name(table) .. ' WHERE `id` = ?', { id })
	end
		
	function database:select_one(table, where_values)
		return self:select_where(table, where_values, 1)
	end
		
	function database:select_where(table, where_values, limit)
		local builder = self:query_builder()
		builder:add('SELECT * FROM')
		builder:add_name(table, true)
		builder:add('WHERE')
		for k, v in pairs(where_values) do
			builder:add_name(k, true)
			builder:add('= ?', { v })
			builder:add('AND')
		end
		builder:remove_trailing('AND')
		if limit then
			builder:add('LIMIT ?', { limit })
		end
		return builder:query()
	end
	
	function database:select_all(table)
		return self:query('SELECT * FROM ' .. database.safe_name(table))
	end

	function database:insert(table, insert_values)
		local builder = self:query_builder()
		builder:add('INSERT INTO')
		builder:add_name(table, true)
		builder:add_names(insert_values, true)
		builder:add('VALUES')
		builder:add_placeholders(insert_values, true)
		return builder:query()
	end

	function database:update(table, id, update_values)
		local builder = self:query_builder()
		builder:add('UPDATE')
		builder:add_name(table, true)
		builder:add('SET')
		for k, v in pairs(update_values) do
			builder:add_name(k, true)
			builder:add('= ?', { v })
			builder:add(',')
		end
		builder:remove_trailing(',')
		builder:add('WHERE `id` = ?', { id })
		return builder:query()
	end

	function database:update_where(table, update_values, where_values, limit)
		local builder = self:query_builder()
		builder:add('UPDATE')
		builder:add_name(table, true)
		builder:add('SET')
		for k, v in pairs(update_values) do
			builder:add_name(k, true)
			builder:add('= ?', { v })
			builder:add(',')
		end
		builder:remove_trailing(',')
		builder:add('WHERE')
		for k, v in pairs(where_values) do
			builder:add_name(k, true)
			builder:add('= ?', { v })
			builder:add('AND')
		end
		builder:remove_trailing('AND')
		if limit then
			builder:add('LIMIT ?', { limit })
		end
		return builder:query()
	end
	
	function database:delete(table, id)
		return self:query('DELETE FROM ' .. database.safe_name(table) .. ' WHERE `id` = ?', { id })
	end
	
	function database:delete_where(table, where_values, limit)
		local builder = self:query_builder()
		builder:add('DELETE FROM')
		builder:add_name(table, true)
		builder:add('WHERE')
		for k, v in pairs(where_values) do
			builder:add_name(k, true)
			builder:add('= ?', { v })
			builder:add('AND')
		end
		builder:remove_trailing('AND')
		if limit then
			builder:add('LIMIT ?', { limit })
		end
		return builder:query()
	end
		
	-- create tables and columns --------------------- -----------------------------------------
	
	function database:has_table(table)
		return self:query('SELECT `name` FROM `sqlite_master` WHERE `type` = ? AND `name` = ?', { 'table', table }).has_rows
	end
	
	function database:has_column(table, column)
		return self:query('SELECT `name` FROM pragma_table_info(?) WHERE `name` = ?', { table, column}).has_rows
	end
	
	function database:ensure_table(table)
		if not self:has_table(table) then
			local builder = self:query_builder()
			builder:add('CREATE TABLE')
			builder:add_name(table, true)
			builder:add('(`id` INTEGER PRIMARY KEY)')
			return builder:query()
		end
	end
	
	function database:ensure_column(table, column, type, default_value)
		if self:has_column(table, column) then
			return
		end
		local builder = self:query_builder()
		builder:add('ALTER TABLE')
		builder:add_name(table, true)
		builder:add('ADD COLUMN')
		builder:add_name(column, true)
		builder:add(type)
		if default_value then
			builder:add('DEFAULT ?', { default_value })
			builder:add('NOT NULL')
		end
		return builder:query()
	end
	
	function database:ensure_index(table, indexed_columns)
		local index_name_parts = prelude.list(indexed_columns)
		index_name_parts:insert(1, 'index')
		local index_name = database.safe_name(index_name_parts:concat('_'), true)
		
		local builder = self:query_builder()
		builder:add('CREATE INDEX IF NOT EXISTS')
		builder:add_name(index_name, true)
		builder:add('ON')
		builder:add_name(table, true)
		builder:add_names(indexed_columns, true)
		return builder:query()
	end

	-- query building ------------------------------------------- ------------------------------
	
	function database.safe_name(name, quote)
		name = name:gsub('[^%w_]', '')
		if quote then
			name = '`' .. name .. '`'
		end
		return name
	end
	
	database.query_builder = class(function (query_builder)
		
		function query_builder:init(database)
			self.database = database
			self.clauses = prelude.list()
			self.bindings = prelude.list(database)
		end
		
		function query_builder:add(clause, bindings)
			self.clauses:push(clause)
			if bindings then
				if #bindings > 0 then
					for _, value in ipairs(bindings) do
						self.bindings:push(value)
					end
				else
					for k, v in pairs(bindings) do
						self.bindings:push(v)
					end
				end
			end
		end
		
		function query_builder:remove_trailing(joiner)
			if self.clauses[#self.clauses] == joiner then
				self.clauses:remove(#self.clauses)
			end
		end
		
		function query_builder:add_name(name, wrap)
			self.clauses:push(database.safe_name(name, wrap))
		end
		
		function query_builder:add_names(names, wrap)
			local names_to_add = prelude.list()
			if #names > 0 then
				for _, name in ipairs(names) do
					names_to_add:push(database.safe_name(name, wrap))
				end
			else
				for k, v in pairs(names) do
					names_to_add:push(database.safe_name(k, wrap))
				end
			end
			if wrap then
				self.clauses:push('(' .. names_to_add:concat(', ') .. ')')
			else
				self.clauses:push(names_to_add:concat(', '))
			end
		end
		
		function query_builder:add_placeholders(bindings, wrap)
			local place_holders_to_add = prelude.list()
			if #bindings > 0 then
				for _, value in ipairs(bindings) do
					place_holders_to_add:push('?')
					self.bindings:push(value)
				end
			else
				for k, v in pairs(bindings) do
					place_holders_to_add:push('?')
					self.bindings:push(v)
				end
			end
			if wrap then
				self.clauses:push('(' .. place_holders_to_add:concat(', ') .. ')')
			else
				self.clauses:push(place_holders_to_add:concat(', '))
			end
		end
		
		function query_builder:query()
			return self.database:query(self.clauses:concat(' '), self.bindings)
		end
		
	end)
	
end)