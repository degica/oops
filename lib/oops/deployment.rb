module Oops
  class Deployment
    def initialize(aws_client, deployment)
      @aws_client = aws_client
      @deployment = deployment
    end

    def self.create(aws_client:, stack_id:, app_id:, instance_ids:, name:, comment: "", args: {})
      deployment = aws_client.create_deployment(
        stack_id: stack_id,
        app_id: app_id,
        comment: comment,
        command: { name: name, args: args },
        instance_ids: instance_ids
      )
      new(aws_client, deployment)
    end

    def run_until_finished
      $stdout.sync = true
      print "Running"
      loop do
        break if finished?
        sleep 5
        putc "."
      end
      raise "Command failed. Please check the OpsWorks console" if failed?
      puts "\nSTATUS: #{status}."
    end

    def status
      @aws_client.describe_deployments(deployment_ids: [@deployment.deployment_id]).deployments[0].status
    end

    def finished?
      status != 'running'
    end

    def failed?
      status == 'failed'
    end
  end
end
