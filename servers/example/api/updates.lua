function api_add_emoji(session, parameters)
	if not is_signed_in(session) then
		error('You must be signed in to add emoji')
	end
	
	-- check valid emoji
	-- valid '👍🏻', '😬', '😅', '😩', '🍃'
	
	local now = utc_time()
	
	-- add to the DB and get the ID
	local id = db:insert('emoji_log', {
		emoji = parameters.emoji,
		identity = session.identity,
		timestamp = now,
	})

	-- return the detail for the new emoji log
	return {
		id = id,
		emoji = parameters.emoji,
		identity = session.identity,
		timestamp = now,
	}
end

function api_delete_emoji(session, parameters)
	if not is_admin(session) then
		error('You must be an admin to delete emojis')
	end
	
	db:delete('emoji_log', parameters.id)
	
	return true
end