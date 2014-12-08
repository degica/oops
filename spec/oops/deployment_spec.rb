require "spec_helper"

describe Oops::Deployment do
  describe ".create" do
    it "creates a new deployment" do
      aws_client, _ = create_deployment

      expect(aws_client).to have_received(:create_deployment).with(
        stack_id: "stack",
        app_id: "app",
        comment: "comment",
        command: { name: "deploy", args: "args"},
        instance_ids: [123]
      )
    end 
  end

  describe "#run_until_finished" do
    before do
      # silence output
      allow($stdout).to receive(:write)
    end

    context "when the deployment is successfull" do
      it "executes until finished" do
        _, deployment = create_deployment

        deployment.run_until_finished

        expect(deployment).to have_received(:finished?)
      end 
    end

    context 'when the deployment fails' do
      it "raises an exception" do
        _, deployment = create_deployment
        allow(deployment).to receive(:failed?).and_return(true)

        expect {
          deployment.run_until_finished
        }.to raise_error(RuntimeError)
      end
    end
  end

  def create_deployment
    aws_client = FakeAwsClient.new("app", "stack")
    allow(aws_client).to receive(:create_deployment)
    deployment = Oops::Deployment.create(
      aws_client: aws_client,
      app_id: "app",
      stack_id: "stack",
      instance_ids: [123],
      name: "deploy",
      comment: "comment",
      args: "args"
    )
    allow(deployment).to receive(:finished?).and_return(true)
    allow(deployment).to receive(:failed?).and_return(false)
    allow(deployment).to receive(:status).and_return(true)
    [aws_client, deployment]
  end
end
