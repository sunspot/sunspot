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
end
