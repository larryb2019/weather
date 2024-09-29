class CreateAddresses < ActiveRecord::Migration[6.1]
  def change
    create_table :addresses do |t|
      t.string :input
      t.datetime :generated_at
      t.string :resolved_as
      t.text :my_uri
      t.text :body

      t.timestamps
    end
  end
end
