require 'mcollective/util/puppetenv/puppetenv'
module MCollective
    module Agent
        class Puppetenv<RPC::Agent
            activate_when do
                true
            end

            def startup_hook
                @puppetenv = Util::Puppetenv.new
            end

            action "list" do
                reply[:environments] = @puppetenv.list
            end

            action "add" do
                validate :environment, String

                @puppetenv.fetch

                reply.fail "Invalid dynamic environment name", 4 unless @puppetenv.validate_environment_name request[:environment]
                
                return unless reply.statuscode == 0

                reply[:status] = @puppetenv.add request[:environment]
            end

            action "update" do
                validate :environment, String

                @puppetenv.fetch

                reply.fail "Invalid dynamic environment name", 4 unless @puppetenv.validate_environment_name request[:environment]
                
                return unless reply.statuscode == 0

                @puppetenv.update request[:environment]
            end

            action "rm" do
                validate :environment, String

                @puppetenv.fetch

                reply.fail "Invalid dynamic environment name", 4 unless @puppetenv.validate_environment_name request[:environment]
                
                return unless reply.statuscode == 0

                @puppetenv.rm request[:environment]
            end

            action "update-all" do
                @puppetenv.fetch
                results = @puppetenv.update_all

                reply[:added]    = results[:added]
                reply[:updated]  = results[:updated]
                reply[:removed]  = results[:removed]
                reply[:rejected] = results[:rejected]
            end
        end
    end
end
