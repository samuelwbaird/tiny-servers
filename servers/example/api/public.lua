function api_emojis(session, parameters)
	local result = db:query('SELECT * FROM `emoji_log` ORDER BY `timestamp` DESC')
	-- return {
	-- 	{ id = 3, emoji = '🍃', identity = 'sam@sam.com', timestamp = 1774048635 },
	-- 	{ id = 2, emoji = '👍', identity = 'sam@sam.com', timestamp = 1774038635 },
	-- 	{ id = 1, emoji = '😩', identity = 'bob@sam.com', timestamp = 1774028635 },
	-- }
	return result.rows
end