class Api::V1::Accounts::SalesController < Api::V1::Accounts::BaseController
  CLOSED_LABEL = 'fechou'.freeze
  LOST_LABEL = 'nao-fechou'.freeze

  # POST /api/v1/accounts/:account_id/sales
  # Registrado ao resolver uma conversa: FECHOU? sim (com valor + hotel) ou não.
  def create
    conversation = Current.account.conversations.find_by!(display_id: params[:conversation_id])
    closed = ActiveModel::Type::Boolean.new.cast(params[:closed])
    hotel = closed ? fetch_allowed_hotel : nil

    sale = Sale.create!(
      account: Current.account,
      conversation: conversation,
      hotel: hotel,
      user: current_user,
      closed: closed,
      value: closed ? params[:value] : 0
    )
    apply_label(conversation, closed ? CLOSED_LABEL : LOST_LABEL)

    render json: sale_json(sale)
  end

  # GET /api/v1/accounts/:account_id/sales/summary?since=&until=
  def summary
    raise Pundit::NotAuthorizedError unless Current.account_user&.administrator?

    scope = Sale.where(account: Current.account).between(range_start, range_end)
    closed = scope.closed_deals

    render json: {
      since: range_start,
      until: range_end,
      closed_count: closed.count,
      lost_count: scope.lost_deals.count,
      total_value: closed.sum(:value).to_f,
      by_hotel: by_hotel_stats(closed),
      by_agent: by_agent_stats(closed),
      recent: recent_sales(closed)
    }
  end

  private

  def fetch_allowed_hotel
    hotels = Hotel.where(account: Current.account).active
    hotels = hotels.for_agent(current_user) unless Current.account_user&.administrator?
    hotels.find(params[:hotel_id])
  end

  def apply_label(conversation, title)
    Current.account.labels.find_or_create_by!(title: title) do |label|
      label.color = title == CLOSED_LABEL ? '#31AF5D' : '#E13939'
      label.description = title == CLOSED_LABEL ? 'Venda fechada' : 'Venda não fechada'
    end
    conversation.add_labels([title])
  end

  def range_start
    @range_start ||= params[:since].present? ? Time.zone.parse(params[:since]) : 30.days.ago.beginning_of_day
  end

  def range_end
    @range_end ||= params[:until].present? ? Time.zone.parse(params[:until]).end_of_day : Time.zone.now
  end

  def by_hotel_stats(closed_scope)
    closed_scope.joins(:hotel).group('hotels.id', 'hotels.name')
                .pluck('hotels.id', 'hotels.name', Arel.sql('COUNT(*)'), Arel.sql('SUM(sales.value)'))
                .map { |id, name, count, value| { id: id, name: name, count: count, value: value.to_f } }
                .sort_by { |row| -row[:value] }
  end

  def by_agent_stats(closed_scope)
    closed_scope.joins(:user).group('users.id', 'users.name')
                .pluck('users.id', 'users.name', Arel.sql('COUNT(*)'), Arel.sql('SUM(sales.value)'))
                .map { |id, name, count, value| { id: id, name: name, count: count, value: value.to_f } }
                .sort_by { |row| -row[:value] }
  end

  def recent_sales(closed_scope)
    closed_scope.includes(:hotel, :user, conversation: :contact)
                .order(created_at: :desc).limit(30)
                .map { |sale| sale_json(sale) }
  end

  def sale_json(sale)
    {
      id: sale.id,
      closed: sale.closed,
      value: sale.value.to_f,
      hotel: sale.hotel&.name,
      agent: sale.user&.name,
      contact: sale.conversation.contact&.name,
      conversation_id: sale.conversation.display_id,
      created_at: sale.created_at
    }
  end
end
