require "spec_helper"

describe Sunspot::Solr::Server do

  describe ".new" do
    it "ensures Java is installed upon initialization" do
      expect(Sunspot::Solr::Java).to receive(:ensure_install!)
      described_class.new
    end
  end

  describe "#bootstrap" do
    it "installs the solr home directory if it doesn't yet exist" do
      specified_dir = Dir.mktmpdir + "/test_directory"
      subject.solr_home = specified_dir
      expect(Sunspot::Solr::Installer).to receive(:execute).
        with(specified_dir, force: true, verbose: true)
      subject.bootstrap
    end
  end

  describe "#run" do
    before { expect(subject).to receive(:bootstrap) }

    it 'runs the Solr server in the foreground' do
      expect(subject).to receive(:exec).with("./solr", "start", "-f", any_args)
      subject.run
    end

    it 'runs the Solr server with the memory specified' do
      subject.memory = 2048
      expect(subject).to receive(:exec).with("./solr", "start", "-f", "-m", "2048", any_args)
      subject.run
    end

    it 'runs the Solr server with the port specified' do
      subject.port = 8981
      expect(subject).to receive(:exec).with("./solr", "start", "-f", "-p", "8981", any_args)
      subject.run
    end

    it 'runs the Solr server with the hostname specified' do
      subject.bind_address = "0.0.0.0"
      expect(subject).to receive(:exec).with("./solr", "start", "-f", "-h", "0.0.0.0", any_args)
      subject.run
    end

    it 'runs the Solr server with the solr home directory specified' do
      specified_dir = Dir.mktmpdir + "/test_directory"
      subject.solr_home = specified_dir
      expect(subject).to receive(:exec).with(any_args, "-s", specified_dir)
      subject.run
    end
  end
end
