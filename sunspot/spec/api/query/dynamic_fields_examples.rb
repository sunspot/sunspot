shared_examples_for "query with dynamic field support" do
  it 'restricts by dynamic string field with equality restriction' do
    search do
      dynamic :custom_string do
        with :test, 'string'
      end
    end
    connection.should have_last_search_including(:fq, 'custom_string\:test_ss:string')
  end

  it 'restricts by dynamic integer field with less than restriction' do
    search do
      dynamic :custom_integer do
        with(:test).less_than(1)
      end
    end
    connection.should have_last_search_including(:fq, 'custom_integer\:test_i:{* TO 1}')
  end

  it 'restricts by dynamic float field with between restriction' do
    search do
      dynamic :custom_float do
        with(:test).between(2.2..3.3)
      end
    end
    connection.should have_last_search_including(:fq, 'custom_float\:test_fm:[2\.2 TO 3\.3]')
  end

  it 'restricts by dynamic time field with any of restriction' do
    search do
      dynamic :custom_time do
        with(:test).any_of([Time.parse('2009-02-10 14:00:00 UTC'),
                            Time.parse('2009-02-13 18:00:00 UTC')])
      end
    end
    connection.should have_last_search_including(:fq, 'custom_time\:test_d:(2009\-02\-10T14\:00\:00Z OR 2009\-02\-13T18\:00\:00Z)')
  end

  it 'restricts by dynamic boolean field with equality restriction' do
    search do
      dynamic :custom_boolean do
        with :test, false
      end
    end
    connection.should have_last_search_including(:fq, 'custom_boolean\:test_b:false')
  end

  it 'negates a dynamic field restriction' do
    search do
      dynamic :custom_string do
        without :test, 'foo'
      end
    end
    connection.should have_last_search_including(:fq, '-custom_string\:test_ss:foo')
  end

  it 'scopes by a dynamic field inside a disjunction' do
    search do
      any_of do
        dynamic :custom_string do
          with :test, 'foo'
        end
        with :title, 'bar'
      end
    end
    connection.should have_last_search_including(
      :fq, '(custom_string\:test_ss:foo OR title_ss:bar)'
    )
  end

  it 'orders by a dynamic field' do
    search do
      dynamic :custom_integer do
        order_by :test, :desc
      end
    end
    connection.should have_last_search_with(:sort => 'custom_integer:test_i desc')
  end

  it 'orders by a dynamic field and static field, with given precedence' do
    search do
      dynamic :custom_integer do
        order_by :test, :desc
      end
      order_by :sort_title, :asc
    end
    connection.should have_last_search_with(:sort => 'custom_integer:test_i desc, sort_title_s asc')
  end

  it 'raises an UnrecognizedFieldError if an unknown dynamic field is searched by' do
    lambda do
      search do
        dynamic(:bogus) { with :some, 'value' }
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'raises a NoMethodError if pagination is attempted in a dynamic query' do
    lambda do
      search do
        dynamic :custom_string do
          paginate :page => 3, :per_page => 10
        end
      end
    end.should raise_error(NoMethodError)
  end

  it 'requests field facet on dynamic field' do
    search do
      dynamic :custom_string do
        facet(:test)
      end
    end
    connection.should have_last_search_including(:"facet.field", 'custom_string:test_ss')
  end

  it 'requests named field facet on dynamic field' do
    search do
      dynamic :custom_string do
        facet(:test, :name => :bogus)
      end
    end
    connection.should have_last_search_including(:"facet.field", '{!key=bogus}custom_string:test_ss')
  end

  it 'requests query facet with internal dynamic field' do
    search do
      facet :test do
        row 'foo' do
          dynamic :custom_string do
            with :test, 'foo'
          end
        end
      end
    end
    connection.should have_last_search_with(
      :"facet.query" => 'custom_string\:test_ss:foo'
    )
  end

  it 'requests query facet with external dynamic field' do
    search do
      dynamic :custom_string do
        facet :test do
          row 'foo' do
            with :test, 'foo'
          end
        end
      end
    end
    connection.should have_last_search_including(
      :"facet.query",
      'custom_string\:test_ss:foo'
    )
  end

  it 'allows scoping on dynamic fields common to all types' do
    search Post, Namespaced::Comment do
      dynamic :custom_float do
        with(:test, 1.23)
      end
    end
    connection.should have_last_search_including(:fq, 'custom_float\\:test_fm:1\\.23')
  end
end
