shared_examples_for 'query with text field scoping' do
  it 'should scope with a text field' do
    search do
      text_fields do
        with(:body, 'test')
      end
    end
    connection.should have_last_search_including(:fq, 'body_textsv:test')
  end

  it 'should raise an UnrecognizedFieldError if differently configured text field is used' do
    lambda do
      search(Post, Namespaced::Comment) do
        text_fields do
          with(:body, 'test')
        end
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should raise an UnrecognizedFieldError if no field exists' do
    lambda do
      search do
        text_fields do
          with(:bogus, 'test')
        end
      end
    end.should raise_error(Sunspot::UnrecognizedFieldError)
  end
end
