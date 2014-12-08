require "spec_helper"

describe Oops::Client do
  describe "#run_command" do
    it "creates and runs a deployment" do
      deployment = double Oops::Deployment
      allow(Oops::Deployment).to receive(:create).and_return(deployment)
      allow(deployment).to receive(:run_until_finished)

      client = stub_with_fake_client
      client.run_command(name: "deploy", args: {})

      expect(deployment).to have_received(:run_until_finished)
    end
  end

  describe "#update_app_url" do
    it "updates the application deploy url" do
      client = stub_with_fake_client 
      allow(client.aws_client).to receive(:update_app)
      file_url = "abc123"

      expect(client.update_app_url(file_url))
      expect(client.aws_client).to have_received(:update_app).with({app_id: client.app_id, app_source: {url: file_url}})
    end
  end

  describe "#stack_id" do
    it "returns the stack id" do
      client = stub_with_fake_client
      expect(client.stack_id).to eq("stack")
    end 
  end

  describe "#app_id" do
    it "returns the app id" do
      client = stub_with_fake_client
      expect(client.app_id).to eq("app")
    end
  end 

  describe "#instance_ids" do
    it "returns instance ids" do
      client = stub_with_fake_client
      expect(client.instance_ids).to eq([123])
    end 
  end

  def stub_with_fake_client
    client = FakeAwsClient.new("app", "stack")
    allow(AWS::OpsWorks::Client).to receive(:new).and_return(client)
    Oops::Client.new("app", "stack")
  end
end
