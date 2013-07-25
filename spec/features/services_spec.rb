require "spec_helper"

if ENV['CF_V2_RUN_INTEGRATION']
  describe "Services" do
    before do
      login
    end

    describe "listing services" do
      it "shows all service instances in the space" do
        pending "Need a test environment to run this against. A1 should soon contain the necessary changes - DS & RT"
        service1 = "some-provided-instance-#{Time.now.to_i}"
        service2 = "cf-managed-instance-#{Time.now.to_i}"
        create_service_instance("user-provided", service1, credentials: { hostname: "myservice.com"} )
        create_service_instance("1", service2, plan: "1")

        BlueShell::Runner.run("#{cf_bin} services") do |runner|
          expect(runner).to say /#{service1}\s+none\s+none\s+none\s+none\s+.*/
        end

      end
    end

    describe "creating a service" do
      describe "when the user leaves the line blank for a plan" do
        it "re-prompts for the plan" do
          BlueShell::Runner.run("#{cf_bin} create-service") do |runner|
            expect(runner).to say "What kind?"
            runner.send_keys "1"
            expect(runner).to say "Name?"
            runner.send_return
            expect(runner).to say "Which plan?"
            runner.send_return
            expect(runner).to say "Which plan?"
          end
        end
      end

      describe "when the service is a user-provided instance" do
        let(:service_name) { "my-private-db-#{Random.rand(1000) + 1000}"}

        it "can create a service instance" do
          pending "Need a test environment to run this against. A1 should soon contain the necessary changes - DS & RT"
          BlueShell::Runner.run("#{cf_bin} create-service") do |runner|
            expect(runner).to say "What kind?"
            runner.send_keys "user-provided"

            expect(runner).to say "Name?"
            runner.send_keys service_name

            expect(runner).to say "What credentials parameters should applications use to connect to this service instance? (e.g. key: uri, value: mysql://username:password@hostname:port/name)
Key"
            runner.send_keys "hostname"
            expect(runner).to say "Value"
            runner.send_keys "myserviceinstance.com"
            expect(runner).to say "Another credentials parameter?"
            runner.send_keys "n"

            expect(runner).to say /Creating service #{service_name}.+ OK/
          end
        end
      end
    end

    describe "binding to a service" do
      let(:app_name) { "env" }
      let(:service_name) { "some-provided-instance-#{Time.now.to_i}" }

      it "can bind and unbind user-provided services to apps" do
        push_app(app_name, app_name, start_command: "'bundle exec ruby env_test.rb -p $PORT'", timeout: 90)
        create_service_instance("user-provided", service_name, credentials: { hostname: "myservice.com"} )

        BlueShell::Runner.run("#{cf_bin} bind-service") do |runner|
          expect(runner).to say "Which application?>"
          runner.send_keys app_name

          expect(runner).to say "Which service?>"
          runner.send_keys service_name

          expect(runner).to say "Binding #{service_name} to #{app_name}... OK"
        end

        BlueShell::Runner.run("#{cf_bin} unbind-service") do |runner|
          expect(runner).to say "Which application?"
          runner.send_keys app_name


        end
      end

      after do
        delete_app(app_name)
      end

      def delete_app(app_name, routes=true)
        delete_cmd = "#{cf_bin} delete #{app_name}"
        delete_cmd + " --routes" if routes
        BlueShell::Runner.run(delete_cmd) do |runner|
          expect(runner).to say "Really delete #{app_name}?"
          runner.send_keys "y"
          expect(runner).to say "Deleting #{app_name}... OK"
        end
      end
    end
  end
end
