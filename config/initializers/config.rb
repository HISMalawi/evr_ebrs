CONFIG = YAML.load_file(Rails.root.join('config', 'couchdb.yml'))[Rails.env]
SETTINGS = YAML.load_file(Rails.root.join('config','settings.yml'))
SYNC_SETTINGS = YAML.load_file(Rails.root.join('config', 'sync_settings.yml'))