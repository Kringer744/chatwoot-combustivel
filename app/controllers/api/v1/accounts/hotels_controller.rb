class Api::V1::Accounts::HotelsController < Api::V1::Accounts::BaseController
  before_action :fetch_hotel, only: [:update, :destroy, :assign_agents]
  before_action :validate_administrator, except: [:index]

  # Admin vê todos os hotéis; consultor vê apenas os hotéis atribuídos a ele
  # (usado no seletor "qual hotel fechou a venda?").
  def index
    hotels = Hotel.where(account: Current.account).order(:name)
    hotels = hotels.active.for_agent(current_user) unless administrator?
    render json: hotels.map { |hotel| hotel_json(hotel) }
  end

  def create
    hotel = Hotel.create!(account: Current.account, name: permitted_params[:name])
    render json: hotel_json(hotel)
  end

  def update
    @hotel.update!(permitted_params)
    render json: hotel_json(@hotel)
  end

  def destroy
    @hotel.destroy!
    head :ok
  end

  # POST /api/v1/accounts/:account_id/hotels/:id/assign_agents
  def assign_agents
    user_ids = Current.account.account_users.where(user_id: params[:user_ids]).pluck(:user_id)
    @hotel.user_ids = user_ids
    render json: hotel_json(@hotel.reload)
  end

  private

  def administrator?
    Current.account_user&.administrator?
  end

  def validate_administrator
    raise Pundit::NotAuthorizedError unless administrator?
  end

  def fetch_hotel
    @hotel = Hotel.where(account: Current.account).find(params[:id])
  end

  def hotel_json(hotel)
    {
      id: hotel.id,
      name: hotel.name,
      active: hotel.active,
      user_ids: hotel.user_ids
    }
  end

  def permitted_params
    params.permit(:name, :active)
  end
end
