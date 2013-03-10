ActiveRecord::Schema.define do
  create_table(:posts, :force => true) do |t|
    t.string :content
    t.integer :region_id
    t.timestamps
  end
end
