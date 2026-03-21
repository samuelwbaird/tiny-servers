function api_add_emoji(session, parameters)
	return true
end

function api_delete_emoji(session, parameters)
	error('You must be an admin to delete emojis')
	
	return true
end