require File.expand_path('../spec_helper', File.dirname(__FILE__))

if Sunspot::Util.child_documents_supported?
  describe 'Block Join queries' do
    let(:children) { Array.new(3) { |i| Child.new(name: "BJ Child #{i}") } }
    let(:parent)   { Parent.new(name: 'BJ Parent', children: children) }

    before :each do
      Sunspot.remove_all! # Ensure to write in a clean index
      Sunspot.index! parent
    end

    after :all do
      Sunspot.remove_all!
    end

    context 'with ChildOf operator' do
      it 'should return correct children using parent name' do
        expect(Sunspot.search(Child) do
          child_of(Parent) { with(:name, parent.name) }
        end.results).to eq(children)
      end

      it 'should not return any children on incorrect parent name' do
        expect(Sunspot.search(Child) do
          child_of(Parent) { with(:name, 'un-existent parent') }
        end.results).to be_empty
      end

      it 'should return correct children in case of complex parent filter' do
        expect(Sunspot.search(Child) do
          child_of(Parent) do
            any_of do
              with(:name, parent.name) # Should match all children
              with(:name, 'un-existent parent')
            end
          end
        end.results).to eq(children)
      end
    end

    context 'with ParentWhich operator' do
      it 'should return correct parent selecting just one child' do
        expect(Sunspot.search(Parent) do
          parent_which(Child) { with(:name, children[0].name) }
        end.results).to eq([parent])
      end

      it 'should return no parent when selecting un-existent child' do
        expect(Sunspot.search(Parent) do
          parent_which(Child) { with(:name, 'un-existent child') }
        end.results).to be_empty
      end

      it 'should return correct parent in case of complex children filter' do
        expect(Sunspot.search(Parent) do
          parent_which(Child) do
            any_of do
              with(:name, children[0].name)
              with(:name, 'un-existent child')
            end
          end
        end.results).to eq([parent])
      end
    end
  end
end