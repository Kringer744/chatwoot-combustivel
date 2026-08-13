# == Schema Information
#
# Table name: hotels
#
#  id         :bigint           not null, primary key
#  active     :boolean          default(TRUE), not null
#  name       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  account_id :bigint           not null
#
class Hotel < ApplicationRecord
  belongs_to :account
  has_many :hotel_agents, dependent: :destroy_async
  has_many :users, through: :hotel_agents
  has_many :sales, dependent: :nullify

  validates :name, presence: true, uniqueness: { scope: :account_id }

  scope :active, -> { where(active: true) }
  scope :for_agent, ->(user) { joins(:hotel_agents).where(hotel_agents: { user_id: user.id }) }
end
