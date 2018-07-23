require File.expand_path('../spec_helper', File.dirname(__FILE__))

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
            review_date: Time.new('2015-001-03T14:30:00Z'),
            stars: 5,
            author: 'yonik',
            comment: 'A great start to what looks like an epic series!'
          ),
          Review.new(
            review_date: Time.new('2014-03-15T12:00:00Z'),
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
            review_date: Time.new('2015-01-03T14:30:00Z'),
            stars: 5,
            author: 'yonik',
            comment: 'Ahead of its time... I wonder if it helped inspire The Matrix?'
          ),
          Review.new(
            review_date: Time.new('2015-04-10T9:00:00Z'),
            stars: 2,
            author: 'dan',
            comment: 'A pizza boy for the Mafia franchise? Really?'
          ),
          Review.new(
            review_date: Time.new('2015-06-02T00:00:00Z'),
            stars: 4,
            author: 'mary',
            comment: 'Neal is so creative and detailed! Loved the metaverse!'
          )
        ]
      )
    ]
  end

  before :each do
    Sunspot.remove_all!
    Sunspot.index! books
  end

  after :each do
    Sunspot.remove_all!
  end
end