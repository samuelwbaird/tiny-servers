local valid_emojis = list({'👍🏻', '😬', '😅', '😩', '🍃'})

-- API add_emoji { emoji = '😬' }
function api_add_emoji(session, parameters)
	if not is_signed_in(session) then
		error('You must be signed in to add emoji')
	end
	
	-- check valid emoji
	if not valid_emojis:contains(parameters.emoji) then
		error('You must select an allowed emoji')
	end
	
	local timestamp = utc_time()
	
	-- add to the DB and get the ID
	local id = db:insert('emoji_log', {
		emoji = parameters.emoji,
		identity = session.identity,
		timestamp = timestamp,
	})

	-- return the detail for the new emoji log
	return {
		id = id,
		emoji = parameters.emoji,
		identity = session.identity,
		timestamp = timestamp,
	}
end

-- API delete_emoji { id = 1 }
function api_delete_emoji(session, parameters)
	if not is_admin(session) then
		error('You must be an admin to delete emojis')
	end
	
	-- delete by id
	db:delete('emoji_log', parameters.id)
	
	-- signal success
	return true
end