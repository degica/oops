require 'ostruct'

class FakeAwsClient
  def initialize(app_name, stack_name)
    @app_name = app_name
    @stack_name = stack_name
  end

  def update_app(app_id:, app_source:)
  end

  def create_deployment(*)
  end

  def describe_instances(stack_id:)
    instances = [OpenStruct.new(instance_id: 123)]
    OpenStruct.new(instances: instances) 
  end

  def describe_stacks
    { stacks: [ { name: @stack_name, stack_id: @stack_name } ] }
  end

  def describe_apps(stack_id:)
    { apps: [ { name: @app_name, app_id: @app_name } ] }
  end
end
