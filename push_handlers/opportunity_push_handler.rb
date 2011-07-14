class OpportunityPushHandler < PushHandler

  def handle_push(user_id, push_hash)
    ConflictManagementUtil.process_opportunity_push(user_id, push_hash)
  end

end