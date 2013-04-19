ActiveRecord::Schema.define do
  create_table(:model_with_disks, :force => true) do |t|
    t.string :content
    t.integer :region_id
    t.timestamps
  end

  create_table(:model_with_second_disks, :force => true) do |t|
    t.string :content
    t.integer :region_id
    t.timestamps
  end

  create_table(:model_with_rts, :force => true) do |t|
    t.string :content
    t.integer :region_id
    t.timestamps
  end

  create_table(:model_with_rt_rubrics, :force => true) do |t|
    t.integer :model_with_rt_id
    t.integer :rubric_id
    t.timestamps
  end

  create_table(:model_with_disk_rubrics, :force => true) do |t|
    t.integer :model_with_disk_id
    t.integer :rubric_id
    t.timestamps
  end

  create_table(:rubrics, :force => true) do |t|
    t.string :name
    t.timestamps
  end
end
