module Oops
  class Client
    attr_reader :aws_client

    def initialize(app_name, stack_name)
      @aws_client = AWS::OpsWorks::Client.new
      @app_name = app_name
      @stack_name = stack_name
    end

    def update_app_url(file_url)
      @aws_client.update_app(app_id: app_id, app_source: { url: file_url })
    end

    def run_command(name:, args:)
      Deployment.create(
        aws_client: @aws_client,
        stack_id: stack_id,
        app_id: app_id,
        instance_ids: instance_ids,
        name: name,
        args: args
      ).run_until_finished
    end

    def stack_id
      @stack_id ||= get_by_name(@aws_client.describe_stacks[:stacks], @stack_name)[:stack_id]
    end

    def app_id
      @app_id ||= get_by_name(@aws_client.describe_apps(stack_id: stack_id)[:apps], @app_name)[:app_id]
    end

    def instance_ids
      @aws_client.describe_instances(stack_id: stack_id).instances.map(&:instance_id).to_a
    end

    private

    def get_by_name collection, name
      collection.detect do |x|
        x[:name] == name
      end || abort("Can't find #{name.inspect} among #{collection.map{|x| x[:name] }.inspect}")
    end
  end
end
