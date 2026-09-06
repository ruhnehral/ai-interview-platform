# frozen_string_literal: true

class Portfolio < ApplicationRecord
  GENERATION_STATUSES = %w[pending generating complete failed].freeze

  # A `generating` row older than this belongs to a worker that died mid-run.
  # Generous enough to cover the 180s Gemini timeout plus Sidekiq's retry backoff.
  STALE_GENERATION_AFTER = 10.minutes

  belongs_to :session
  has_many :portfolio_skills, dependent: :destroy
  has_many :assessor_overrides, through: :portfolio_skills

  validates :generation_status, inclusion: { in: GENERATION_STATUSES }
  validates :generation_attempts, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :complete,    -> { where(generation_status: 'complete') }
  scope :failed,      -> { where(generation_status: 'failed') }
  scope :generating,  -> { where(generation_status: 'generating') }
  scope :stuck_generating, lambda {
    generating.where('generation_started_at IS NULL OR generation_started_at < ?', STALE_GENERATION_AFTER.ago)
  }

  def complete?    = generation_status == 'complete'
  def generating?  = generation_status == 'generating'
  def failed?      = generation_status == 'failed'

  # True when this row claims to be generating but nothing is actually working on it.
  # Rows created before the generation-tracking migration have a nil
  # generation_started_at, so they read as stale and become reclaimable — that is
  # deliberate, it is how the already-stuck portfolios recover.
  def generation_stale?
    return false unless generating?

    generation_started_at.nil? || generation_started_at < STALE_GENERATION_AFTER.ago
  end
end
