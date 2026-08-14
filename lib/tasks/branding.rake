namespace :branding do
  desc 'Sincroniza as configs de marca do installation_config.yml para o banco'
  task sync: :environment do
    keys = %w[INSTALLATION_NAME BRAND_NAME LOGO LOGO_DARK LOGO_THUMBNAIL ENABLE_ACCOUNT_SIGNUP]
    ConfigLoader.new.general_configs.each do |config|
      next unless keys.include?(config['name'])

      record = InstallationConfig.find_or_initialize_by(name: config['name'])
      record.value = config['value']
      record.save!
    end
    GlobalConfig.clear_cache
    puts 'branding:sync ok'
  end
end
