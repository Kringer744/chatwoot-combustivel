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

  desc 'Desbloqueia recursos premium/enterprise e Captain para todas as contas (self-hosted)'
  task unlock: :environment do
    plan = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN')
    plan.value = 'enterprise'
    plan.save!
    qty = InstallationConfig.find_or_initialize_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
    qty.value = 1000
    qty.save!
    GlobalConfig.clear_cache

    features = %w[
      captain_integration captain_integration_v2 captain_v1_action_classifier
      captain_document_auto_sync captain_tasks custom_tools
      audit_logs sla custom_roles disable_branding help_center_embedding_search
      linear_integration notion_integration shopify_integration
      channel_voice advanced_search advanced_search_indexing advanced_assignment
      companies crm crm_v2 assignment_v2 whatsapp_campaign data_import
      conversation_required_attributes csat_review_notes
    ]
    Account.find_each do |account|
      account.enable_features!(*features)
    end

    # contas novas (criadas pelo super admin) já nascem com tudo liberado
    defaults = InstallationConfig.find_or_initialize_by(name: 'ACCOUNT_LEVEL_FEATURE_DEFAULTS')
    current = Array(defaults.value).map { |f| f.with_indifferent_access }
    features.each do |name|
      entry = current.find { |f| f[:name] == name }
      entry ? entry[:enabled] = true : current << { name: name, enabled: true }
    end
    defaults.value = current
    defaults.save!
    puts "branding:unlock ok (#{Account.count} contas, plano enterprise)"
  rescue StandardError => e
    puts "branding:unlock ERRO: #{e.message}"
  end
end
