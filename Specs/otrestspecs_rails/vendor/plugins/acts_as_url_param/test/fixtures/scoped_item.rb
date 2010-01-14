class ActsAsUrlParam::ScopedItem < ActsAsUrlParam::Item
  acts_as_url_param :scope => 'items.scope_by_id = #{self.scope_by_id}', :redirectable => true
end