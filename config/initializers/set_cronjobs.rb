cron_tab_entries = `crontab -l`
PATH=`echo $PATH`
unless cron_tab_entries.include?("PATH")
	path = "(crontab -l 2>/dev/null; echo 'PATH=#{PATH}') | crontab -"
	`#{path}`
end
app_root = Rails.root
entries_to_add = [		
					"*/5 * * * * bash -l -c 'cd #{app_root} && bundle exec rails r bin/sync_background.rb'"
					"0 */2 * * * bash -l -c 'cd #{app_root} && bundle exec rails r bin/sync_previous.rb'"
				]
entries_to_add.each do |entry|
	next if cron_tab_entries.include?(entry)
	new_entry = "(crontab -l 2>/dev/null; echo \"#{entry}\") | crontab -"
	`#{new_entry}`
end