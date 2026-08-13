# == Schema Information
#
# Table name: sales
#
#  id              :bigint           not null, primary key
#  closed          :boolean          default(FALSE), not null
#  value           :decimal(12, 2)   default(0.0), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :bigint           not null
#  conversation_id :bigint           not null
#  hotel_id        :bigint
#  user_id         :bigint
#
class Sale < ApplicationRecord
  belongs_to :account
  belongs_to :conversation
  belongs_to :hotel, optional: true
  belongs_to :user, optional: true

  validates :value, numericality: { greater_than_or_equal_to: 0 }
  validates :hotel, presence: true, if: :closed?

  scope :closed_deals, -> { where(closed: true) }
  scope :lost_deals, -> { where(closed: false) }
  scope :between, ->(since, until_time) { where(created_at: since..until_time) }
end
