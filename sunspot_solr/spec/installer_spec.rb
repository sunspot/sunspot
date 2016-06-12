require "spec_helper"

describe Sunspot::Solr::Installer do
  let(:install_dir) { Pathname(Dir.mktmpdir + "/test_install_directory") }
  let(:install_manifest) do
    [ "solr.xml",
      "configsets/sunspot/conf/_rest_managed.json",
      "configsets/sunspot/conf/admin-extra.html",
      "configsets/sunspot/conf/currency.xml",
      "configsets/sunspot/conf/elevate.xml",
      "configsets/sunspot/conf/lang/stopwords_en.txt",
      "configsets/sunspot/conf/mapping-ISOLatin1Accent.txt",
      "configsets/sunspot/conf/protwords.txt",
      "configsets/sunspot/conf/schema.xml",
      "configsets/sunspot/conf/scripts.conf",
      "configsets/sunspot/conf/solrconfig.xml",
      "configsets/sunspot/conf/spellings.txt",
      "configsets/sunspot/conf/synonyms.txt",
      "default/core.properties",
      "development/core.properties",
      "test/core.properties" ]
  end

  let(:destination_files) { install_manifest.map { |file| install_dir.join(file) } }

  it "creates the install directory" do
    expect { described_class.execute(install_dir.to_s) }.
      to change { install_dir.exist? }.from(false).to(true)
  end

  it "installs the Solr config files into the specified directory" do
    described_class.execute(install_dir.to_s)
    installed_files = Pathname.glob(install_dir.join("**/*")).select(&:file?)
    expect(installed_files).to contain_exactly(*destination_files).and all( be_exist )
  end

  describe "force" do
    let(:existing_file) { install_dir.join("solr.xml") }

    before do
      install_dir.mkpath
      File.write(existing_file, "Hello, World!")
    end

    it "does not overwrite existing files when 'force' is false (default)" do
      expect { described_class.execute(install_dir) }.
        not_to change { existing_file.read }.from "Hello, World!"
    end

    it "overwrites existing files when 'force' is true" do
      expect { described_class.execute(install_dir, force: true) }.
        to change { existing_file.read }.
        from("Hello, World!").
        to(%r{<solr>(.|\n)*</solr>})
    end
  end

  describe "verbose" do
    let(:fake_stdout) { StringIO.new }

    before do
      stub_const("STDOUT", fake_stdout)
      install_dir.mkpath
      File.write(install_dir.join("solr.xml"), "Hello, World!")
    end

    it "does not output to STDOUT when 'verbose' is false (default)" do
      described_class.execute(install_dir, force: true)
      fake_stdout.rewind
      expect(fake_stdout.read).to be_empty
    end

    it "outputs to STDOUT when 'verbose' is true" do
      described_class.execute(install_dir, force: true, verbose: true)
      fake_stdout.rewind
      expect(fake_stdout.read).
        to  match(/Removing existing file .+/).
        and match(/Creating directory .+/).
        and match(/Copying .+ => .+/)
    end
  end
end
