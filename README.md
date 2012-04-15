# Sunspot

[![Build Status](https://secure.travis-ci.org/sunspot/sunspot.png)](http://travis-ci.org/sunspot/sunspot)

Sunspot is a Ruby library for expressive, powerful interaction with the Solr
search engine. Sunspot is built on top of the RSolr library, which
provides a low-level interface for Solr interaction; Sunspot provides a simple,
intuitive, expressive DSL backed by powerful features for indexing objects and
searching for them.

Sunspot is designed to be easily plugged in to any ORM, or even non-database-backed
objects such as the filesystem.

This README provides a high level overview; class-by-class and
method-by-method documentation is available in the [API
reference](http://sunspot.github.com/sunspot/docs/).

## Quickstart with Rails 3

Add to Gemfile:

```ruby
gem 'sunspot_rails'
gem 'sunspot_solr' # optional pre-packaged Solr distribution for use in development
```

Bundle it!

```bash
bundle install
```

Generate a default configuration file:

```bash
rails generate sunspot_rails:install
```

If `sunspot_solr` was installed, start the packaged Solr distribution
with:

```bash
bundle exec rake sunspot:solr:start # or sunspot:solr:run to start in foreground
```

## Setting Up Objects

Add a `searchable` block to the objects you wish to index.

```ruby
class Post < ActiveRecord::Base
  searchable do
    text :title, :body
    text :comments do
      comments.map { |comment| comment.body }
    end

    boolean :featured
    integer :blog_id
    integer :author_id
    integer :category_ids, :multiple => true
    double  :average_rating
    time    :published_at
    time    :expired_at

    string  :sort_title do
      title.downcase.gsub(/^(an?|the)/, '')
    end
  end
end
```

`text` fields will be full-text searchable. Other fields (e.g.,
`integer` and `string`) can be used to scope queries.

## Searching Objects

```ruby
Post.search do
  fulltext 'best pizza'

  with :blog_id, 1
  with(:published_at).less_than Time.now
  order_by :published_at, :desc
  paginate :page => 2, :per_page => 15
  facet :category_ids, :author_id
end
```

## Search In Depth

Given an object `Post` setup in earlier steps ...

### Full Text

```ruby
# All posts with a `text` field (:title, :body, or :comments) containing 'pizza'
Post.search { fulltext 'pizza' }

# Posts with pizza, scored higher if pizza appears in the title
Post.search do
  fulltext 'pizza' do
    boost_fields :title => 2.0
  end
end

# Posts with pizza, scored higher if featured
Post.search do
  fulltext 'pizza' do
    boost(2.0) { with(:featured, true) }
  end
end

# Posts with pizza *only* in the title
Post.search do
  fulltext 'pizza' do
    fields(:title)
  end
end

# Posts with pizza in the title (boosted) or in the body (not boosted)
Post.search do
  fulltext 'pizza' do
    fields(:body, :title => 2.0)
  end
end
```

#### Phrases

Solr allows searching for phrases: search terms that are close together.

In the default query parser used by Sunspot (dismax), phrase searches
are represented as a double quoted group of words.

```ruby
# Posts with the exact phrase "great pizza"
Post.search do
  fulltext '"great pizza"'
end
```

If specified, **query_phrase_slop** sets the number of words that may
appear between the words in a phrase.

```ruby
# One word can appear between the words in the phrase, so "great big pizza"
# also matches, in addition to "great pizza"
Post.search do
  fulltext '"great pizza"' do
    query_phrase_slop 1
  end
end
```

##### Phrase Boosts

Phrase boosts add boost to terms that appear in close proximity;
the terms do not *have* to appear in a phrase, but if they do, the
document will score more highly.

```ruby
# Matches documents with great and pizza, and scores documents more
# highly if the terms appear in a phrase in the title field
Post.search do
  fulltext 'great pizza' do
    phrase_fields :title => 2.0
  end
end

# Matches documents with great and pizza, and scores documents more
# highly if the terms appear in a phrase (or with one word between them)
# in the title field
Post.search do
  fulltext 'great pizza' do
    phrase_fields :title => 2.0
    phrase_slop   1
  end
end
```

### Scoping (Scalar Fields)

Fields not defined as `text` (e.g., `integer`, `boolean`, `time`,
etc...) can be used to scope (restrict) queries before full-text
matching is performed.

#### Positive Restrictions

```ruby
# Posts with a blog_id of 1
Post.search do
  with(:blog_id, 1)
end

# Posts with an average rating between 3.0 and 5.0
Post.search do
  with(:average_rating, 3.0..5.0)
end

# Posts with a category of 1, 3, or 5
Post.search do
  with(:category_ids, [1, 3, 5])
end

# Posts published since a week ago
Post.search do
  with(:published_at).greater_than(1.week.ago)
end
```

#### Negative Restrictions

```ruby
# Posts not in category 1 or 3
Post.search do
  without(:category_ids, [1, 3])
end

# All examples in "positive" also work negated using `without`
```

#### Disjunctions and Conjunctions

```ruby
# Posts that do not have an expired time or have not yet expired
Post.search do
  any_of do
    with(:expired_at).greater_than(Time.now)
    with(:expired_at, nil)
  end
end
```

```ruby
# Posts with blog_id 1 and author_id 2
Post.search do
  all_of do
    with(:blog_id, 1)
    with(:author_id, 2)
  end
end
```

Disjunctions and conjunctions may be nested

```ruby
Post.search do
  any_of do
    with(:blog_id, 1)
    all_of do
      with(:blog_id, 2)
      with(:category_ids, 3)
    end
  end
end
```

#### Combined with Full-Text

Scopes/restrictions can be combined with full-text searching. The
scope/restriction pares down the objects that are searched for the
full-text term.

```ruby
# Posts with blog_id 1 and 'pizza' in the title
Post.search do
  with(:blog_id, 1)
  fulltext("pizza")
end
```

### Pagination

**All results from Solr are paginated**

The results array that is returned has methods mixed in that allow it to
operate seamlessly with common pagination libraries like will\_paginate
and kaminari.

By default, Sunspot requests the first 30 results from Solr.

```ruby
search = Post.search do
  fulltext "pizza"
end

# Imagine there are 60 *total* results (at 30 results/page, that is two pages)
results = search.results # => Array with 30 Post elements

search.total           # => 60

results.total_pages    # => 2
results.first_page?    # => true
results.last_page?     # => false
results.previous_page  # => nil
results.next_page      # => 2
results.out_of_bounds? # => false
results.offset         # => 0
```

To retrieve the next page of results, recreate the search and use the
`paginate` method.

```ruby
search = Post.search do
  fulltext "pizza"
  paginate :page => 2
end

# Again, imagine there are 60 total results; this is the second page
results = search.results # => Array with 30 Post elements

search.total           # => 60

results.total_pages    # => 2
results.first_page?    # => false
results.last_page?     # => true
results.previous_page  # => 1
results.next_page      # => nil
results.out_of_bounds? # => false
results.offset         # => 30
```

A custom number of results per page can be specified with the
`:per_page` option to `paginate`:

```ruby
search = Post.search do
  fulltext "pizza"
  paginate :page => 1, :per_page => 50
end
```

### Faceting

Faceting is a feature of Solr that determines the number of documents
that match a given search *and* an additional criterion. This allows you
to build powerful drill-down interfaces for search.

Each facet returns zero or more rows, each of which represents a
particular criterion conjoined with the actual query being performed.
For **field facets**, each row represents a particular value for a given
field. For **query facets**, each row represents an arbitrary scope; the
facet itself is just a means of logically grouping the scopes.

#### Field Facets

```ruby
# Posts that match 'pizza' returning counts for each :author_id
search = Post.search do
  fulltext "pizza"
  facet :author_id
end

search.facet(:author_id).rows.each do |facet|
  puts "Author #{facet.value} has #{facet.count} pizza posts!"
end
```

#### Query Facets

```ruby
# Posts faceted by ranges of average ratings
search = Post.search do
  facet(:average_rating) do
    row(1.0..2.0) do
      with(:average_rating, 1.0..2.0)
    end
    row(2.0..3.0) do
      with(:average_rating, 2.0..3.0)
    end
    row(3.0..4.0) do
      with(:average_rating, 3.0..4.0)
    end
    row(4.0..5.0) do
      with(:average_rating, 4.0..5.0)
    end
  end
end

# e.g.,
# Number of posts with rating withing 1.0..2.0: 2
# Number of posts with rating withing 2.0..3.0: 1
search.facet(:average_rating).rows.each do |facet|
  puts "Number of posts with rating withing #{facet.value}: #{facet.count}"
end
```

#### Range Facets

```ruby
# Posts faceted by range of average ratings
Sunspot.search(Post) do
  facet :average_rating, :range => 1..5, :range_interval => 1
end
```

### Ordering

By default, Sunspot orders results by "score": the Solr-determined
relevancy metric. Sorting can be customized with the `order_by` method:

```ruby
# Order by average rating, descending
Post.search do
  fulltext("pizza")
  order_by(:average_rating, :desc)
end

# Order by relevancy score and in the case of a tie, average rating
Post.search do
  fulltext("pizza")

  order_by(:score, :desc)
  order_by(:average_rating, :desc)
end

# Randomized ordering
Post.search do
  fulltext("pizza")
  order_by(:random)
end
```

### Grouping

**Solr 3.3 and above**

Solr supports grouping documents, similar to an SQL `GROUP BY`. More
information about result grouping/field collapsing is available on the
[Solr Wiki](http://wiki.apache.org/solr/FieldCollapsing).

**Grouping is only supported on `string` fields that are not
multivalued. To group on a field of a different type (e.g., integer),
add a denormalized `string` type**

```ruby
class Post < ActiveRecord::Base
  searchable do
    # Denormalized `string` field because grouping can only be performed
    # on string fields
    string(:blog_id_str) { |p| p.blog_id.to_s }
  end
end

# Returns only the top scoring document per blog_id
search = Post.search do
  group :blog_id_str
end

search.group(:blog_id_str).matches # Total number of matches to the query

search.group(:blog_id_str).groups.each do |group|
  puts group.value # blog_id of the each document in the group

  # By default, there is only one document per group (the highest
  # scoring one); if `limit` is specified (see below), multiple
  # documents can be returned per group
  group.results.each do |result|
    # ...
  end
end
```

Additional options are supported by the DSL:

```ruby
# Returns the top 3 scoring documents per blog_id
Post.search do
  group :blog_id_str do
    limit 3
  end
end

# Returns document ordered within each group by published_at (by
# default, the ordering is score)
Post.search do
  group :blog_id_str do
    order_by(:average_rating, :desc)
  end
end

# Facet count is based on the most relevant document of each group
# matching the query (>= Solr 3.4)
Post.search do
  group :blog_id_str do
    truncate
  end

  facet :blog_id_str, :extra => :any
end
```

### Geospatial

**Experimental and unreleased. The DSL may change.**

Sunspot 2.0 supports geospatial features of Solr 3.1 and above.

Geospatial features require a field defined with `latlon`:

```ruby
class Post < ActiveRecord::Base
  searchable do
    # ...
    latlon(:location) { Sunspot::Util::Coordinates.new(lat, lon) }
  end
end
```

#### Filter By Radius

```ruby
# Searches posts within 100 kilometers of (32, -68)
Post.search do
  with(:location).in_radius(32, -68, 100)
end
```

#### Filter By Radius (inexact with bbox)

```ruby
# Searches posts within 100 kilometers of (32, -68) with `bbox`. This is
# an approximation so searches run quicker, but it may include other
# points that are slightly outside of the required distance
Post.search do
  with(:location).in_radius(32, -68, 100, :bbox => true)
end
```

#### Filter By Bounding Box

```ruby
# Searches posts within the bounding box defined by the corners (45,
# -94) to (46, -93)
Post.search do
  with(:location).in_bounding_box([45, -94], [46, -93])
end
```

#### Sort By Distance

```ruby
# Orders documents by closeness to (32, -68)
Post.search do
  order_by_geodist(:location, 32, -68)
end
```

### Highlighting

Highlighting allows you to display snippets of the part of the document
that matched the query.

The fields you wish to highlight must be **stored**.

```ruby
class Post < ActiveRecord::Base
  searchable do
    # ...
    text :body, :stored => true
  end
end
```

Highlighting matches on the `body` field, for instance, can be acheived
like:

```ruby
search = Post.search do
  fulltext "pizza" do
    highlight :body
  end
end

# Will output something similar to:
# Post #1
#   I really love *pizza*
#   *Pizza* is my favorite thing
# Post #2
#   Pepperoni *pizza* is delicious
search.hits.each do |hit|
  puts "Post ##{hit.primary_key}"

  hit.highlights(:body).each do |highlight|
    puts "  " + highlight.format { |word| "*#{word}*" }
  end
end
```

### Functions

TODO

### More Like This

Sunspot can extract related items using more_like_this. When searching 
for similar items, you can pass a block with the following options:

* fields :field_1[, :field_2, ...]
* minimum_term_frequency ##
* minimum_document_frequency ##
* minimum_word_length ##
* maximum_word_length ##
* maximum_query_terms ##
* boost_by_relevance true/false

```ruby
class Post < ActiveRecord::Base
  searchable do
    # The :more_like_this option must be set to true
    text :body, :more_like_this => true
  end
end

post = Post.first

results = Sunspot.more_like_this(post) do
  fields :body
  minimum_term_frequency 5
end
```

## Indexing In Depth

TODO

### Index-Time Boosts

To specify that a field should be boosted in relation to other fields for
all queries, you can specify the boost at index time:

```ruby
class Post < ActiveRecord::Base
  searchable do
    text :title, :boost => 5.0
    text :body
  end
end
```

### Stored Fields

Stored fields keep an original (untokenized/unanalyzed) version of their
contents in Solr.

Stored fields allow data to be retrieved without also hitting the
underlying database (usually an SQL server). They are also required for
highlighting and more like this queries.

Stored fields come at some performance cost in the Solr index, so use
them wisely.

```ruby
class Post < ActiveRecord::Base
  searchable do
    text :body, :stored => true
  end
end

# Retrieving stored contents without hitting the database
Post.search.hits.each do |hit|
  puts hit.stored(:body)
end
```

## Hits vs. Results

Sunspot simply stores the type and primary key of objects in Solr.
When results are retrieved, those primary keys are used to load the
actual object (usually from an SQL database).

```ruby
# Using #results pulls in the records from the object-relational
# mapper (e.g., ActiveRecord + a SQL server)
Post.search.results.each do |result|
  puts result.body
end
```

To access information about the results without querying the underlying
database, use `hits`:

```ruby
# Using #hits gives back all information requested from Solr, but does
# not load the object from the object-relational mapper
Post.search.hits.each do |hit|
  puts hit.stored(:body)
end
```

If you need both the result (ORM-loaded object) and `Hit` (e.g., for
faceting, highlighting, etc...), you can use the convenience method
`each_hit_with_result`:

```ruby
Post.search.each_hit_with_result do |hit, result|
  # ...
end
```

## Reindexing Objects

If you are using Rails, objects are automatically indexed to Solr as a
part of the `save` callbacks.

If you make a change to the object's "schema" (code in the `searchable` block),
you must reindex all objects so the changes are reflected in Solr:

```bash
bundle exec rake sunspot:solr:reindex

# or, to be specific to a certain model with a certain batch size:
bundle exec rake sunspot:solr:reindex[500,Post] # some shells will require escaping [ with \[ and ] with \]
```

## Use Without Rails

TODO

## Manually Adjusting Solr Parameters

To add or modify parameters sent to Solr, use `adjust_solr_params`:

```ruby
Post.search do
  adjust_solr_params do |params|
    params[:q] += " AND something_s:more"
  end
end
```

## Session Proxies

TODO

## Type Reference

TODO

## Development

### Running Tests

#### sunspot

Install the required gem dependencies:

```bash
cd /path/to/sunspot/sunspot
bundle install
```

Start a Solr instance on port 8983:

```bash
bundle exec sunspot-solr start -p 8983
# or `bundle exec sunspot-solr run -p 8983` to run in foreground
```

Run the tests:

```bash
bundle exec rake spec
```

If desired, stop the Solr instance:

```bash
bundle exec sunspot-solr stop
```

#### sunspot\_rails

Install the gem dependencies for `sunspot`:

```bash
cd /path/to/sunspot/sunspot
bundle install
```

Start a Solr instance on port 8983:

```bash
bundle exec sunspot-solr start -p 8983
# or `bundle exec sunspot-solr run -p 8983` to run in foreground
```

Navigate to the `sunspot_rails` directory:

```bash
cd ../sunspot_rails
```

Run the tests:

```bash
rake spec # all Rails versions
rake spec RAILS=3.1.1 # specific Rails version only
```

If desired, stop the Solr instance:

```bash
cd ../sunspot
bundle exec sunspot-solr stop
```

### Generating Documentation

Install the `yard` and `redcarpet` gems:

```bash
$ gem install yard redcarpet
```

Uninstall the `rdiscount` gem, if installed:

```bash
$ gem uninstall rdiscount
```

Generate the documentation from topmost directory:

```bash
$ yardoc -o docs */lib/**/*.rb - README.md
```

## Tutorials and Articles

* [Using Sunspot, Websolr, and Solr on Heroku](http://mrdanadams.com/2012/sunspot-websolr-solr-heroku/) (mrdanadams)
* [Full Text Searching with Solr and Sunspot](http://collectiveidea.com/blog/archives/2011/03/08/full-text-searching-with-solr-and-sunspot/) (Collective Idea)
* [Full-text search in Rails with Sunspot](http://tech.favoritemedium.com/2010/01/full-text-search-in-rails-with-sunspot.html) (Tropical Software Observations)
* [Sunspot Full-text Search for Rails/Ruby](http://therailworld.com/posts/23-Sunspot-Full-text-Search-for-Rails-Ruby) (The Rail World)
* [A Few Sunspot Tips](http://blog.trydionel.com/2009/11/19/a-few-sunspot-tips/) (spiral_code)
* [Sunspot: A Solr-Powered Search Engine for Ruby](http://www.linux-mag.com/id/7341) (Linux Magazine)
* [Sunspot Showed Me the Light](http://bennyfreshness.com/2010/05/sunspot-helped-me-see-the-light/) (ben koonse)
* [RubyGems.org — A case study in upgrading to full-text search](http://blog.websolr.com/post/3505903537/rubygems-search-upgrade-1) (Websolr)
* [How to Implement Spatial Search with Sunspot and Solr](http://codequest.eu/articles/how-to-implement-spatial-search-with-sunspot-and-solr) (Code Quest)
* [Sunspot 1.2 with Spatial Solr Plugin 2.0](http://joelmats.wordpress.com/2011/02/23/getting-sunspot-1-2-with-spatial-solr-plugin-2-0-to-work/) (joelmats)
* [rails3 + heroku + sunspot : madness](http://anhaminha.tumblr.com/post/632682537/rails3-heroku-sunspot-madness) (anhaminha)
* [How to get full text search working with Sunspot](http://cookbook.hobocentral.net/recipes/57-how-to-get-full-text-search) (Hobo Cookbook)
* [Full text search with Sunspot in Rails](http://hemju.com/2011/01/04/full-text-search-with-sunspot-in-rail/) (hemju)
* [Using Sunspot for Free-Text Search with Redis](http://masonoise.wordpress.com/2010/02/06/using-sunspot-for-free-text-search-with-redis/) (While I Pondered...)
* [Fuzzy searching in SOLR with Sunspot](http://www.pipetodevnull.com/past/2010/8/5/fuzzy_searching_in_solr_with_sunspot/) (pipe :to => /dev/null)
* [Default scope with Sunspot](http://www.cloudspace.com/blog/2010/01/15/default-scope-with-sunspot/) (Cloudspace)
* [Index External Models with Sunspot/Solr](http://www.medihack.org/2011/03/19/index-external-models-with-sunspotsolr/) (Medihack)
* [Chef recipe for Sunspot in production](http://gist.github.com/336403)
* [Testing with Sunspot and Cucumber](http://collectiveidea.com/blog/archives/2011/05/25/testing-with-sunspot-and-cucumber/) (Collective Idea)
* [Cucumber and Sunspot](http://opensoul.org/2010/4/7/cucumber-and-sunspot) (opensoul.org)
* [Testing Sunspot with Cucumber](http://blog.trydionel.com/2010/02/06/testing-sunspot-with-cucumber/) (spiral_code)
* [Running cucumber features with sunspot_rails](http://blog.kabisa.nl/2010/02/03/running-cucumber-features-with-sunspot_rails) (Kabisa Blog)
* [Testing Sunspot with Test::Unit](http://timcowlishaw.co.uk/post/3179661158/testing-sunspot-with-test-unit) (Type Slowly)
* [How To Use Twitter Lists to Determine Influence](http://www.untitledstartup.com/2010/01/how-to-use-twitter-lists-to-determine-influence/) (Untitled Startup)
* [Sunspot Quickstart](http://wiki.websolr.com/index.php/Sunspot_Quickstart) (WebSolr)
* [Solr, and Sunspot](http://www.kuahyeow.com/2009/08/solr-and-sunspot.html) (YT!)
* [The Saga of the Switch](http://mrb.github.com/2010/04/08/the-saga-of-the-switch.html) (mrb -- includes comparison of Sunspot and Ultrasphinx)
* [Conditional Indexing with Sunspot](http://mikepackdev.com/blog_posts/19-conditional-indexing-with-sunspot) (mikepack)

## License

Sunspot is distributed under the MIT License, copyright (c) 2008-2009 Mat Brown
