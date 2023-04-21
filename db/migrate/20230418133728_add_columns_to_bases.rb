class AddColumnsToBases < ActiveRecord::Migration[5.1]
  def change
    add_column :bases, :base_number, :integer
    add_column :bases, :base_name, :string
    add_column :bases, :attendance_type, :string
  end
end
