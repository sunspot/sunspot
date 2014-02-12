require File.expand_path("../spec_helper", File.dirname(__FILE__))
require File.expand_path("../helpers/search_helper", File.dirname(__FILE__))

describe 'select' do
  describe 'Given a Search' do
    subject {
      Sunspot.new_search(Post)
    }

    let(:selects) {
      subject.query.to_params[:fl]
    }

    context 'when assigned stored fields to be selected' do
      before do
        subject.build do |query|
          query.select(:title)
          query.select(:featured)
        end
      end

      it 'selects the specified indexed fields' do
        selects.should include('title_ss featured_bs')
      end

      it 'does NOT select *' do
        selects.should_not include('*')
      end

      it 'selects required fields for Hit generation' do
        selects.should include(Sunspot::Search::Hit::SPECIAL_KEYS.to_a.join(' '))
      end
    end

    context 'when assigned with the from options containing a function query' do
      before do
        subject.build do |query|
          query.select(:distance, from: "geodist(location,123,455)")
        end
      end

      it 'selects the field with the function query' do
        selects.should include('distance:geodist(location,123,455)')
      end
    end

    context 'when assigned with the from options containing a stored field' do
      before do
        subject.build do |query|
          query.select(:name, from: :title)
        end
      end

      it 'selects the field with the function query' do
        selects.should include('name:title_ss')
      end
    end

    context 'when I do not assign any fields to be selected' do
      it 'should select all fields' do
        selects.should include('*')
      end
    end

  end
end
