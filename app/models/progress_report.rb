class ProgressReport < VersionedRecord
  belongs_to :indicator
  belongs_to :due_date, required: false
  has_many :measures, through: :indicator
  has_many :recommendations, through: :measures
  has_many :categories, through: :recommendations
  has_one :manager, through: :indicator

  validates :title, presence: true
  validates :indicator_id, presence: true
end
