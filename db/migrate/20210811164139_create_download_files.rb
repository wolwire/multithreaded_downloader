# frozen_string_literal: true

class CreateDownloadFiles < ActiveRecord::Migration[6.1]
  def change
    create_table :download_files do |t|
      t.string :name
      t.string :url
      t.string :size
      t.timestamps
    end
  end
end
