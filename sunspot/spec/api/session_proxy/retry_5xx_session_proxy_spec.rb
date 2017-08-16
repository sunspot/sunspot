require File.expand_path('spec_helper', File.dirname(__FILE__))

describe Sunspot::SessionProxy::Retry5xxSessionProxy do
  
  before :each do
    Sunspot::Session.connection_class = Mock::ConnectionFactory.new
    @sunspot_session = Sunspot.session
    @proxy = Sunspot::SessionProxy::Retry5xxSessionProxy.new(@sunspot_session)
    Sunspot.session = @proxy
  end

  after :each do
    Sunspot::Session.connection_class = nil
    Sunspot.reset!(true)
  end

  class FakeRSolrErrorHttp < RSolr::Error::Http
    def backtrace
      []
    end
  end

  let :fake_rsolr_request do
    {:uri => 'http://solr.test/uri'}
  end

  def fake_rsolr_response(status)
    {:status => status.to_s}
  end

  let :post do
    Post.new(:title => 'test')
  end

  it "should behave normally without a stubbed exception" do
    expect(@sunspot_session).to receive(:index).and_return(double)
    Sunspot.index(post)
  end

  it "should be successful with a single exception followed by a sucess" do
    e = FakeRSolrErrorHttp.new(fake_rsolr_request, fake_rsolr_response(503))
    expect(@sunspot_session).to receive(:index) do
      expect(@sunspot_session).to receive(:index).and_return(double)
      raise e
    end
    Sunspot.index(post)
  end

  it "should return the error response after two exceptions" do
    fake_response = fake_rsolr_response(503)
    e = FakeRSolrErrorHttp.new(fake_rsolr_request, fake_response)
    fake_success = double('success')

    expect(@sunspot_session).to receive(:index) do
      expect(@sunspot_session).to receive(:index) do
        allow(@sunspot_session).to receive(:index).and_return(fake_success)
        raise e
      end
      raise e
    end

    response = Sunspot.index(post)
    expect(response).not_to eq(fake_success)
    expect(response).to eq(fake_response)
  end

  it "should not retry a 4xx" do
    e = FakeRSolrErrorHttp.new(fake_rsolr_request, fake_rsolr_response(400))
    expect(@sunspot_session).to receive(:index).and_raise(e)
    expect { Sunspot.index(post) }.to raise_error
  end

  # TODO: try against more than just Sunspot.index? but that's just testing the
  # invocation of delegate, so probably not important. -nz 11Apr12

  it_should_behave_like 'session proxy'
  
end
