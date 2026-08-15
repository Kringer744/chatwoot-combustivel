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

  desc 'Garante o Super Admin: cria com SUPERADMIN_EMAIL/SUPERADMIN_PASSWORD ou promove usuário existente'
  task superadmin: :environment do
    email = ENV['SUPERADMIN_EMAIL']
    password = ENV['SUPERADMIN_PASSWORD']
    user = email.present? ? User.from_email(email) : (SuperAdmin.none? ? User.order(:id).first : nil)

    if user.nil? && email.present? && password.present?
      user = User.new(name: 'Super Admin', email: email, password: password, type: 'SuperAdmin')
      user.skip_confirmation!
      user.save!
      puts "branding:superadmin #{email} criado"
    elsif user.nil?
      puts 'branding:superadmin nada a fazer'
    elsif user.type == 'SuperAdmin'
      puts "branding:superadmin #{user.email} já é super admin"
    else
      user.update!(type: 'SuperAdmin')
      puts "branding:superadmin #{user.email} promovido"
    end
  rescue StandardError => e
    # nunca derrubar o boot por causa do super admin; o erro fica no log
    puts "branding:superadmin ERRO: #{e.message}"
  end
end
