class CreateTimelines < ActiveRecord::Migration[6.1]
  def change
    create_table :timelines do |t|
      t.string :timeline
      t.references :download_file
      t.timestamps
    end
  end
end
