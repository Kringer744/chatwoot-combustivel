class Uazapi::Client
  class ApiError < StandardError; end

  def initialize(server_url)
    @base_url = server_url.to_s.strip.chomp('/')
    raise ApiError, 'UAZAPI server URL is required' if @base_url.blank?
  end

  def create_instance(name:, admin_token:)
    request(:post, '/instance/create', payload: { name: name }, headers: { admintoken: admin_token })
  end

  def connect(token)
    request(:post, '/instance/connect', payload: {}, headers: { token: token })
  end

  def status(token)
    request(:get, '/instance/status', headers: { token: token })
  end

  def disconnect(token)
    request(:post, '/instance/disconnect', payload: {}, headers: { token: token })
  end

  def set_chatwoot_config(token, config)
    request(:put, '/chatwoot/config', payload: config, headers: { token: token })
  end

  private

  def request(method, path, payload: nil, headers: {})
    response = RestClient::Request.execute(
      method: method,
      url: "#{@base_url}#{path}",
      payload: payload&.to_json,
      headers: headers.merge(content_type: :json, accept: :json),
      timeout: 30
    )
    response.body.present? ? JSON.parse(response.body) : {}
  rescue RestClient::ExceptionWithResponse => e
    raise ApiError, error_message_from(e)
  rescue SocketError, Errno::ECONNREFUSED, RestClient::Exceptions::Timeout => e
    raise ApiError, "Não foi possível conectar ao servidor UAZAPI (#{e.class})"
  end

  def error_message_from(error)
    body = JSON.parse(error.response.body)
    body['error'] || body['message'] || error.message
  rescue JSON::ParserError
    error.message
  end
end
