# == Schema Information
#
# Table name: hotel_agents
#
#  id         :bigint           not null, primary key
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  hotel_id   :bigint           not null
#  user_id    :bigint           not null
#
class HotelAgent < ApplicationRecord
  belongs_to :hotel
  belongs_to :user

  validates :user_id, uniqueness: { scope: :hotel_id }
end
