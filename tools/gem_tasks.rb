require 'rubygems/specification'

module Sunspot
  class GemTasks
    PROJECT_ROOT = File.dirname(Rake.application.rakefile_location)

    def initialize(dependencies = {}, &block)
      @dependencies = dependencies
      @gemspec_block = block

      task(:gemspec, "Write gemspec")
      task(:build, "Build gem")
      task(:tag, "Tag version in Git and push to origin")
      task(:release, "Release gem to Gemcutter")
    end

    def build
      run_dependencies(:build)
      filename = Gem::Builder.new(spec).build
      FileUtils.mv(filename, File.join(PROJECT_ROOT, 'pkg'))
      File.join('pkg', filename)
    end

    def tag
      tag_name = "v#{spec.version}"
      puts `git tag -m "Released gem version #{spec.version}" #{tag_name}`
      puts `git push origin #{tag_name}:#{tag_name}`
    end

    def release
      validate_or_abort
      tag
      puts `gem push #{build}`
    end

    def gemspec
      File.open(File.join(PROJECT_ROOT, "#{spec.name}.gemspec"), 'w') do |file|
        file << spec.to_ruby
      end
    end

    def spec
      @spec ||= Gem::Specification.new(&@gemspec_block)
    end

    def validate_or_abort
      begin
        spec.validate
      rescue Gem::InvalidSpecificationException => e
        abort("Gemspec is invalid: #{e.message}")
      end
    end

    private

    def task(name, description)
      Rake.application.last_description = description
      Rake::Task.define_task(name) { send(name) }
    end

    def run_dependencies(task)
      if @dependencies[task]
        Array(@dependencies[task]).each do |dependency|
          Rake::Task[dependency].invoke
        end
      end
    end
  end
end
