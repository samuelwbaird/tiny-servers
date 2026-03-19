function prepare()
	-- create a global DB object
	db = database('example')
	
	-- ensure table exists, with a primary auto `id` column by default
	db:ensure_table('emoji_log')
	-- add required columns
	db:ensure_column('emoji_log', 'emoji', db.TEXT)
	db:ensure_column('emoji_log', 'timestamp', db.TIMESTAMP)
	db:ensure_column('emoji_log', 'email', db.TEXT)
	-- add required indexes
	db:ensure_index('emoji_log', ['timestamp'])
end

function is_admin(session)
	local valid_admin_emails = list({ 'samuelwbaird@gmail.com' })
	return session.logged_in and valid_admin_emails:includes(session.email)
end