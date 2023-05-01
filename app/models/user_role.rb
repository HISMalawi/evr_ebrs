class UserRole < ActiveRecord::Base
    self.table_name = :user_role
    self.primary_key = :user_role_id
    include EbrsAttribute
    belongs_to :role, class_name: 'Role', foreign_key: 'role_id'

end
