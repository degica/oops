require 'oops/client'
require 'oops/deployment'
require 'aws'
require 'rake'

module Oops
  class Tasks
    attr_accessor :prerequisites, :additional_paths, :includes, :excludes, :format

    def self.default_args
      {
        prerequisites: ['assets:clean', 'assets:precompile'],
        additional_paths: [],
        includes: ['public/assets'],
        excludes: ['.gitignore'],
        format: 'zip'
      }
    end

    def initialize(&block)
      self.class.default_args.each do |key, value|
        public_send("#{key}=", value)
      end
      yield(self)
      create_task!
    end

    def add_file file_path, path
      if format == 'zip'
        sh *%W{zip -r -g build/#{file_path} #{path}}
      elsif format == 'tar'
        sh *%W{tar -r -f build/#{file_path} #{path}}
      end
    end

    def remove_file file_path, path
      if format == 'zip'
        sh *%W{zip build/#{file_path} -d #{path}}
      elsif format == 'tar'
        sh *%W{tar --delete -f build/#{file_path} #{path}}
      end
    end

    private
    include Rake::DSL
    def create_task!
      # Remove any existing definition
      Rake::Task["oops:build"].clear if Rake::Task.task_defined?("oops:build")

      namespace :oops do
        task :build, [:filename] => prerequisites do |t, args|
          args.with_defaults filename: default_filename

          file_path = args.filename

          sh %{mkdir -p build}
          sh %{git archive --format #{format} --output build/#{file_path} HEAD}

          (includes + additional_paths).each do |path|
            add_file file_path, path
          end

          excludes.each do |path|
            remove_file file_path, path
          end

          puts "Packaged Application: #{file_path}"
        end
      end
    end
  end
end

# Initialize build task with defaults
Oops::Tasks.new do
end

namespace :oops do
  task :upload, :filename do |t, args|
    args.with_defaults filename: default_filename

    file_path = args.filename
    s3 = s3_object(file_path)

    puts "Starting upload..."
    s3.write(file: "build/#{file_path}")
    puts "Uploaded Application: #{s3.url_for(:read)}"
  end

  task :recipe, :app_name, :stack_name, :recipe do |t, args|
    raise "app_name variable is required" unless args.app_name
    raise "stack_name variable is required" unless args.stack_name
    raise "recipe variable is required" unless args.recipe

    client = Oops::Client.new(args.app_name, args.stack_name)
    client.run_command(name: "execute_recipes", comment: args.recipe, args: {"recipes" => [args.recipe]})
  end

  task :deploy, :app_name, :stack_name, :filename do |t, args|
    raise "app_name variable is required" unless args.app_name
    raise "stack_name variable is required" unless args.stack_name
    args.with_defaults filename: default_filename
    file_path = args.filename
    file_url = s3_url file_path

    ENV['AWS_REGION'] = 'us-east-1'

    if !s3_object(file_path).exists?
      raise "Artifact \"#{file_url}\" doesn't seem to exist\nMake sure you've run `RAILS_ENV=deploy rake opsworks:build opsworks:upload` before deploying"
    end

    client = Oops::Client.new(args.app_name, args.stack_name)
    client.update_app_url(file_url)
    client.run_command(name: "deploy", args: {"migrate" => "true"})
  end

  private
  def s3_object file_path
    AWS::S3.new.buckets[bucket_name].objects["#{package_folder}/#{file_path}"]
  end

  def s3_url file_path
    s3_object(file_path).public_url.to_s
  end

  def build_hash
    @build_hash ||= `git rev-parse HEAD`.strip
  end

  def default_filename
    ENV['PACKAGE_FILENAME'] || "git-#{build_hash}.zip"
  end

  def package_folder
    raise "PACKAGE_FOLDER environment variable required" unless ENV['PACKAGE_FOLDER']
    ENV['PACKAGE_FOLDER']
  end

  def bucket_name
    raise "DEPLOY_BUCKET environment variable required" unless ENV['DEPLOY_BUCKET']
    ENV['DEPLOY_BUCKET']
  end

end
