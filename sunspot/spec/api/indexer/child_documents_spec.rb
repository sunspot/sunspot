require File.expand_path('spec_helper', File.dirname(__FILE__))

describe 'indexing child documents fields', type: :indexer do
  let(:children) { Array.new(3) { |i| Child.new(name: "Child #{i}") } }
  let(:parent)   { Parent.new(name: 'Parent', children: children) }

  it 'should index both parent and children' do
    session.index(parent)
    expect(connection).to have_add_with(name_s: parent.name)
    add_children = values_in_last_document_for(RSolr::Document::CHILD_DOCUMENT_KEY)
    expect(add_children.length).to eq(children.length)
    add_children.each_with_index do |child, i|
      expect(child.field_by_name(:name_s).value).to eq(children[i].name)
    end
  end
end
