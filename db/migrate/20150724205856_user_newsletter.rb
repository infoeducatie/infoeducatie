class UserNewsletter < ActiveRecord::Migration
  def change
    add_column :users, :newsletter, :boolean
  end
end
