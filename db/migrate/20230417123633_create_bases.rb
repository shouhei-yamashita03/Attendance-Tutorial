class CreateBases < ActiveRecord::Migration[5.1]
  def change
    create_table :bases do |t|
      t.text :content

      t.timestamps
    end
  end
end
