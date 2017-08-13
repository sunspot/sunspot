shared_examples_for 'query with text field scoping' do
  it 'should scope with a text field' do
    search do
      text_fields do
        with(:body, 'test')
      end
    end
    expect(connection).to have_last_search_including(:fq, 'body_textsv:test')
  end

  it 'should raise an UnrecognizedFieldError if differently configured text field is used' do
    expect do
      search(Post, Namespaced::Comment) do
        text_fields do
          with(:body, 'test')
        end
      end
    end.to raise_error(Sunspot::UnrecognizedFieldError)
  end

  it 'should raise an UnrecognizedFieldError if no field exists' do
    expect do
      search do
        text_fields do
          with(:bogus, 'test')
        end
      end
    end.to raise_error(Sunspot::UnrecognizedFieldError)
  end
end
