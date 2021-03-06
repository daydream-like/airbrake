if Gem::Version.new(RUBY_VERSION) >= Gem::Version.new('2.2.2')
  require 'sidekiq'
  require 'sidekiq/cli'
  require 'airbrake/sidekiq'

  RSpec.describe "airbrake/sidekiq/error_handler" do
    let(:endpoint) { 'https://api.airbrake.io/api/v3/projects/113743/notices' }

    def wait_for_a_request_with_body(body)
      wait_for(a_request(:post, endpoint).with(body: body)).to have_been_made.once
    end

    def call_handler
      handler = Sidekiq.error_handlers.last
      handler.call(
        AirbrakeTestError.new('sidekiq error'),
        'class' => 'HardSidekiqWorker', 'args' => %w[bango bongo]
      )
    end

    before do
      stub_request(:post, endpoint).to_return(status: 201, body: '{}')
    end

    it "sends a notice to Airbrake" do
      expect(call_handler).to be_a(Airbrake::Promise)

      wait_for_a_request_with_body(/"message":"sidekiq\serror"/)
      wait_for_a_request_with_body(/"params":{.*"args":\["bango","bongo"\]/)
      wait_for_a_request_with_body(/"component":"sidekiq","action":"HardSidekiqWorker"/)
    end
  end
end
