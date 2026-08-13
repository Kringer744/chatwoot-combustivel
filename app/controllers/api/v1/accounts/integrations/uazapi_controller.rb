class Api::V1::Accounts::Integrations::UazapiController < Api::V1::Accounts::BaseController
  before_action :validate_administrator
  before_action :set_inbox, only: [:status, :disconnect]

  # POST /api/v1/accounts/:account_id/integrations/uazapi
  # Cria a instância na UAZAPI, cria a inbox (canal API) e inicia a conexão (QR code)
  def create
    client = Uazapi::Client.new(permitted_params[:server_url])
    instance = client.create_instance(
      name: permitted_params[:instance_name],
      admin_token: permitted_params[:admin_token]
    )
    token = instance['token']
    raise Uazapi::Client::ApiError, 'UAZAPI não retornou o token da instância' if token.blank?

    inbox = build_inbox(token)
    connection = client.connect(token)

    render json: {
      inbox_id: inbox.id,
      qrcode: connection.dig('instance', 'qrcode'),
      paircode: connection.dig('instance', 'paircode'),
      status: connection.dig('instance', 'status'),
      connected: connection['connected'],
      logged_in: connection['loggedIn']
    }
  rescue Uazapi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # GET /api/v1/accounts/:account_id/integrations/uazapi/status?inbox_id=
  # Faz o polling da conexão; quando o WhatsApp loga, configura a integração
  # Chatwoot dentro da UAZAPI e grava o webhook na inbox — tudo automático.
  def status
    client = Uazapi::Client.new(uazapi_config['server_url'])
    response = client.status(uazapi_config['token'])
    instance = response['instance'] || {}
    logged_in = response.dig('status', 'loggedIn') || false

    configure_chatwoot_integration(client, instance) if logged_in && !uazapi_config['configured']

    render json: {
      status: instance['status'],
      connected: response.dig('status', 'connected'),
      logged_in: logged_in,
      qrcode: instance['qrcode'],
      paircode: instance['paircode'],
      profile_name: instance['profileName'],
      owner: instance['owner'],
      configured: @inbox.channel.reload.additional_attributes.dig('uazapi', 'configured') || false
    }
  rescue Uazapi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /api/v1/accounts/:account_id/integrations/uazapi/disconnect
  def disconnect
    client = Uazapi::Client.new(uazapi_config['server_url'])
    client.disconnect(uazapi_config['token'])
    update_uazapi_config('configured' => false)
    head :ok
  rescue Uazapi::Client::ApiError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def validate_administrator
    raise Pundit::NotAuthorizedError unless Current.account_user&.administrator?
  end

  def set_inbox
    @inbox = Current.account.inboxes.find(params[:inbox_id])
    raise Uazapi::Client::ApiError, 'Inbox não tem configuração UAZAPI' if uazapi_config.blank?
  end

  def uazapi_config
    @inbox.channel.additional_attributes['uazapi'] || {}
  end

  def build_inbox(token)
    channel = Channel::Api.create!(
      account: Current.account,
      additional_attributes: {
        'uazapi' => {
          'server_url' => permitted_params[:server_url].to_s.strip.chomp('/'),
          'token' => token,
          'instance_name' => permitted_params[:instance_name],
          'configured' => false
        }
      }
    )
    Current.account.inboxes.create!(
      name: permitted_params[:inbox_name].presence || "WhatsApp · #{permitted_params[:instance_name]}",
      channel: channel
    )
  end

  def configure_chatwoot_integration(client, instance)
    response = client.set_chatwoot_config(
      uazapi_config['token'],
      enabled: true,
      url: ENV.fetch('FRONTEND_URL', ''),
      access_token: current_user.access_token.token,
      account_id: Current.account.id,
      inbox_id: @inbox.id,
      ignore_groups: false,
      sign_messages: false,
      create_new_conversation: false
    )
    webhook_url = response['chatwoot_inbox_webhook_url']
    @inbox.channel.update!(webhook_url: webhook_url) if webhook_url.present?
    update_uazapi_config(
      'configured' => true,
      'owner' => instance['owner'],
      'profile_name' => instance['profileName']
    )
  end

  def update_uazapi_config(changes)
    channel = @inbox.channel
    attrs = channel.additional_attributes.deep_dup
    attrs['uazapi'] = (attrs['uazapi'] || {}).merge(changes)
    channel.update!(additional_attributes: attrs)
  end

  def permitted_params
    params.permit(:server_url, :admin_token, :instance_name, :inbox_name, :inbox_id)
  end
end
