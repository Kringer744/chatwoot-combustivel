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

  desc 'Promove um usuário a Super Admin (SUPERADMIN_EMAIL ou, sem env, o primeiro usuário)'
  task superadmin: :environment do
    user = if ENV['SUPERADMIN_EMAIL'].present?
             User.from_email(ENV['SUPERADMIN_EMAIL'])
           elsif SuperAdmin.none?
             User.order(:id).first
           end
    if user.nil?
      puts 'branding:superadmin nada a fazer'
    elsif user.type == 'SuperAdmin'
      puts "branding:superadmin #{user.email} já é super admin"
    else
      user.update!(type: 'SuperAdmin')
      puts "branding:superadmin #{user.email} promovido"
    end
  end
end
