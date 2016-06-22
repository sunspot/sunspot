require "spec_helper"

describe Sunspot::Solr::Java do

  describe ".ensure_install!" do
    subject { described_class.ensure_install! }

    context "when Java is installed" do
      before { expect(described_class).to receive(:installed?) { true } }
      it { should be true }
    end

    context "when Java is not installed" do
      before { expect(described_class).to receive(:installed?) { false } }
      it "should raise a JavaMissing error" do
        expect { subject }.
          to raise_error Sunspot::Solr::Server::JavaMissing, /You need a Java/
      end
    end
  end

  describe ".installed?" do
    subject { described_class.installed? }

    context "when Java can be found" do
      let(:command) { system("echo") }
      before do
        expect(described_class).to receive(:system).
          with("java", "-version", [:out, :err] => "/dev/null") { system("echo", out: "/dev/null") }
      end
      it { should be true }
    end

    context "when Java cannot be found" do
      before do
        expect(described_class).to receive(:system).
          with("java", "-version", [:out, :err] => "/dev/null") { system("some-command-not-found") }
      end
      it { should be false }
    end
  end

  describe ".null_device" do
    subject { described_class.null_device }

    before { stub_const("RbConfig::CONFIG", { "host_os" => host_os }) }

    context "when the OS is Windows" do
      let(:host_os) { "mswin32" }
      it { should eq "NUL" }
    end

    context "when the OS is not Windows" do
      let(:host_os) { "darwin15.2.0" }
      it { should eq "/dev/null" }
    end
  end
end
