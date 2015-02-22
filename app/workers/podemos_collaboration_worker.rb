require 'podemos_export'

class PodemosCollaborationWorker
  @queue = :podemos_collaboration_queue

  def self.perform collaboration_id
    if collaboration_id==-1
      today = Date.today
      export_data Collaboration.temp_bank_filename(today, false), Collaboration.joins(:order).includes(:user).where.not(payment_type: 1).merge(Order.by_date(today,today)), nil, "tmp/export", true do |collaboration|
        collaboration.skip_queries_validations = true
        collaboration.get_bank_data today
      end
    else
      collaboration = Collaboration.find(collaboration_id)
      collaboration.charge!
    end
  end
end