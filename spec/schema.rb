ActiveRecord::Schema.define(:version => 0) do
  create_table :posts, :force => true do |t|
    t.string :title
    t.text :body
    t.references :blog
    t.timestamps
  end

  create_table :blogs, :force => true do |t|
    t.string :name
    t.string :subdomain
    t.timestamps
  end

  create_table :writers, :force => true, :primary_key => :writer_id do |t|
    t.string :name
    t.timestamps
  end

end
