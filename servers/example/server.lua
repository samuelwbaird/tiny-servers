-- the prepare function is run everytime this tiny server is relaunched
function prepare()
	log('prepare')
	-- create a global DB object (not local), it will be available in any api function
	db = database('example')
	
	-- ensure table exists, with a primary auto `id` column by default
	db:ensure_table('emoji_log')
	-- add required columns
	db:ensure_column('emoji_log', 'emoji', 'TEXT')
	db:ensure_column('emoji_log', 'timestamp', 'INT')	-- unix time
	db:ensure_column('emoji_log', 'identity', 'TEXT')
	-- add required indexes
	db:ensure_index('emoji_log', { 'timestamp' })
end


-- make some shared functions that can be used by any API
function is_signed_in(session)
	return session.identity ~= nil and session.identity ~= ''
end

function is_admin(session)
	local valid_admin_emails = list({ 'admin@admin.com' })
	return valid_admin_emails:contains(session.identity)
end