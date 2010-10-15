
module Bones::Plugins::Rcov
  include ::Bones::Helpers
  extend self

  def initialize_rcov
    require 'rcov'
    require 'rcov/rcovtask'
    have?(:rcov) { true }

    ::Bones.config {
      desc 'Configuration settings for the Rcov code coverage tool.'
      rcov {
        path 'rcov', :desc => <<-__
          Path to the rcov executable.
        __

        dir 'coverage', :desc => <<-__
          Code coverage metrics will be written to this directory.
        __

        opts %w[--sort coverage -T], :desc => <<-__
          An array of command line options that will be passed to the rcov
          command when running your tests. See the Rcov help documentation
          either online or from the command line by running 'rcov --help'.
        __

        threshold 90.0, :desc => <<-__
          The threshold value (in percent) for coverage. If the actual
          coverage is not greater than or equal to this value, the verify task
          will raise an exception.
        __

        threshold_exact false, :desc => <<-__
          Require the threshold to be met exactly. By default this option is
          set to false.
        __
      }
    }
  rescue LoadError
    have?(:rcov) { false }
  end

  def post_load
    return unless have? :rcov
    config = ::Bones.config
    config.exclude << "^#{Regexp.escape(config.rcov.dir)}/"
  end

  def define_tasks
    return unless have? :rcov
    config = ::Bones.config

    if have? :test
      namespace :test do
        desc 'Run rcov on the unit tests'
        Rcov::RcovTask.new do |t|
          t.output_dir = config.rcov.dir
          t.rcov_opts = config.rcov.opts
          t.ruby_opts = config.ruby_opts.dup.concat(config.test.opts)

          t.test_files =
              if test(?f, config.test.file) then [config.test.file]
              else config.test.files.to_a end

          t.libs = config.libs unless config.libs.empty?
        end

        task :clobber_rcov do
          rm_r config.rcov.dir rescue nil
        end
      end
      task :clobber => 'test:clobber_rcov'
    end
  end

end  # module Bones::Plugins::Rcov

