require File.expand_path('../spec_helper', File.dirname(__FILE__))

if Sunspot::Util.child_documents_supported?
  describe 'Block Join faceting with JSON API' do
    let :books do
      [
        Book.new(
          title: 'The Way of Kings',
          author: 'Brandon Sanderson',
          category: 'fantasy',
          pub_year: 2010,
          reviews: [
            Review.new(
              book_id: 1,
              review_date: DateTime.parse('2015-01-03T14:30:00Z'),
              stars: 5,
              author: 'yonik',
              comment: 'A great start to what looks like an epic series!'
            ),
            Review.new(
              book_id: 1,
              review_date: DateTime.parse('2014-03-15T12:00:00Z'),
              stars: 3,
              author: 'dan',
              comment: 'This book was way too long.'
            )
          ]
        ),
        Book.new(
          title: 'Snow Crash',
          author: 'Neal Stephenson',
          category: 'sci-fi',
          pub_year: 1992,
          reviews: [
            Review.new(
              book_id: 2,
              review_date: DateTime.parse('2015-01-03T14:30:00Z'),
              stars: 5,
              author: 'yonik',
              comment: 'Ahead of its time... I wonder if it helped inspire The Matrix?'
            ),
            Review.new(
              book_id: 2,
              review_date: DateTime.parse('2015-04-10T9:00:00Z'),
              stars: 2,
              author: 'dan',
              comment: 'A pizza boy for the Mafia franchise? Really?'
            ),
            Review.new(
              book_id: 2,
              review_date: DateTime.parse('2015-06-02T00:00:00Z'),
              stars: 4,
              author: 'mary',
              comment: 'Neal is so creative and detailed! Loved the metaverse!'
            )
          ]
        ),
        Book.new(
          title: 'Dark Tower: The Gunslinger',
          author: 'Stephen King',
          category: 'fantasy',
          pub_year: 1982,
          reviews: [
            Review.new(
              book_id: 3,
              review_date: DateTime.parse('2017-09-03T15:13:25Z'),
              stars: 3,
              author: 'richard',
              comment: 'I know, I\'m the only person who doesn\'t like it, but I just couldn\'t get into it.'
            ),
            Review.new(
              book_id: 3,
              review_date: DateTime.parse('2017-06-02T07:00:00Z'),
              stars: 5,
              author: 'moore',
              comment: 'It\'s my third time reading this series, I believe this one is my favorite.'
            ),
            Review.new(
              book_id: 3,
              review_date: DateTime.parse('2017-12-24T16:27:19Z'),
              stars: 1,
              author: 'roxanne',
              comment: 'This book was a very slow read and it felt like it never got to a point.'
            )
          ]
        )
      ]
    end

    before :each do
      Sunspot.remove_all!
      Sunspot.index! books
    end

    after :all do
      Sunspot.remove_all!
    end

    it 'search children by filter and facet on parent field' do
      search = Sunspot.search(Review) do
        with :author, 'yonik'
        json_facet :category, block_join: on_parent(Book) {}
      end

      expect(search.facet(:category).rows.size).to eq(2)
      expect(search.facet(:category).rows.map(&:value).uniq).to eq(%w[fantasy sci-fi])
    end

    it 'search parents by filter and facet on child field' do
      search = Sunspot.search(Book) do
        fulltext books[0].title, fields: [:title]
        json_facet :review_date, block_join: (on_child(Review) do
          with(:review_date).greater_than(DateTime.parse('2015-01-01T00:00:00Z'))
        end)
      end

      expect(search.facet(:review_date).rows.size).to eq(1)
      found_value = DateTime.parse(search.facet(:review_date).rows[0].value)
      expect(found_value).to eq(books[0].reviews[0].review_date)
    end

    it 'search parents by filter and facet on child field (using minimum match)' do
      search = Sunspot.search(Book) do
        fulltext books[0].title, fields: [:title], minimum_match: 1
        json_facet :review_date, block_join: (on_child(Review) do
          with(:review_date, (DateTime.parse('2015-01-01T00:00:00Z')..DateTime.parse('2017-01-01T00:00:00Z')))
        end)
      end

      expect(search.facet(:review_date).rows.size).to eq(1)
      found_value = DateTime.parse(search.facet(:review_date).rows[0].value)
      expect(found_value).to eq(books[0].reviews[0].review_date)
    end

    context 'stats' do
      it 'executes correct stats on children using block join faceting' do
        search = Sunspot.search(Book) do
          fulltext(books[0].title, fields: [:title])
          stats :stars, sort: :avg, on: Review do
            json_facet :book_id, block_join: (on_child(Review) {})
          end
        end

        expect(search.json_facet_stats(:book_id).rows.length).to eq(1)
        expect(search.json_facet_stats(:book_id).rows[0].min).to eq(3.0)
        expect(search.json_facet_stats(:book_id).rows[0].max).to eq(5.0)
        expect(search.json_facet_stats(:book_id).rows[0].avg).to eq(4.0)
      end

      it 'executes correct stats on parents using block join faceting' do
        search = Sunspot.search(Review) do
          with(:stars).greater_than(2.0)
          stats :pub_year, sort: :min, on: Book do
            json_facet :category, block_join: (on_parent(Book) {})
          end
        end

        rows = search.json_facet_stats(:category).rows
        expect(rows.length).to eq(2)
        expect(rows[0].min).to eq(books[1].pub_year)
        expect(rows[0].max).to eq(books[1].pub_year)
        expect(rows[1].min).to eq(books[2].pub_year)
        expect(rows[1].max).to eq(books[0].pub_year)
      end
    end
  end
end