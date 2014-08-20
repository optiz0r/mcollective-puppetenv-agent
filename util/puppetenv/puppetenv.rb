require "fileutils"
require "rugged"
require "shellwords"

module MCollective
    module Util
        class Puppetenv

            attr_reader :puppetenv

            def initialize
                config = Config.instance

                @basedir = config.pluginconf.fetch('puppetenv.basedir', '/home/puppet')
                @upstream = config.pluginconf.fetch('puppetenv.upstream', 'origin')
                @username = config.pluginconf.fetch('puppetenv.username', 'git')
                @publickey = config.pluginconf.fetch('puppetenv.publickey', "#{ENV['HOME']}/.ssh/id_rsa.pub")
                @privatekey = config.pluginconf.fetch('puppetenv.privatekey', "#{ENV['HOME']}/.ssh/id_rsa")
                @passphrase = config.pluginconf.fetch('puppetenv.passphrase', '')
                @master_repo_name = config.pluginconf.fetch('puppetenv.master_repo', '.puppet.git')
                @master_repo_path = File.join(@basedir, @master_repo_name)

                @new_workdir = config.pluginconf.fetch('puppetenv.new_workdir', '/usr/share/git/contrib/workdir/git-new-workdir')
                @credentials = Rugged::Credentials::SshKey.new({
                    username:   @username,
                    publickey:  @publickey,
                    privatekey: @privatekey,
                    passphrase: @passphrase
                })

                @master_repo = Rugged::Repository.new(@master_repo_path)
            end

            def list
                environments = []

                Dir.foreach(@basedir) { |item|
                    if item.start_with?('.') then
                        next
                    end
                    environments << item
                }

                environments
            end

            def add(name)
                workdir = File.join(@basedir, name)
                command = "#{@new_workdir} '#{@master_repo_path.shellescape}' '#{workdir.shellescape}' '#{name}' 2>&1"
                output = `#{command}`
                result = $?
                Log.debug("Executed command \"#{command}\" with return code '#{result}' and output '#{output}'")
                return output

            end

            def update(name)
                workdir = File.join(@basedir, name)
                repo = Rugged::Repository.new(workdir)
                repo.reset("refs/remotes/#{@upstream}/#{name}", :hard)
                return true
            end

            def rm(name)
                workdir = File.join(@basedir, name)
                FileUtils.rm_rf(workdir)
            end

            def update_all
                results = {
                    :added =>  [],
                    :updated => [],
                    :removed => [],
                    :rejected => []
                }
                @master_repo.refs("refs/remotes/#{@upstream}/*").each do |ref|
                    branch = ref.name["refs/remotes/#{@upstream}/".length, ref.name.length]
                    environment = File.join(@basedir, branch)
                    if Dir.exists?(environment)
                        results[:updated] << branch
                        update(branch)
                    else
                        if validate_environment_name(branch)
                            results[:added] << branch
                            add(branch)
                        else
                            results[:rejected] << branch
                        end
                    end
                end

                Dir.glob(File.join(@basedir, '*')).each do |path|
                    environment = path[@basedir.length + 1, path.length]
                    Log.debug("Checking #{environment}")
                    ref = @master_repo.ref("refs/remotes/#{@upstream}/#{environment}")
                    if not ref
                        results[:removed] << environment
                        rm(environment)
                    end
                end

                return results
            end

            def validate_environment_name(name)
                # Verify the name is valid as a puppet environment
                return false unless name.match(/^[a-zA-Z0-9_]+$/)

                # Verify the name corresponds with an existing git branch
                return false unless @master_repo.references["refs/remotes/#{@upstream}/#{name}"]

                return true
            end

            def fetch
                @master_repo.remotes.each do |remote|
                    if remote.name() == @upstream
                        remote.fetch(remote.fetch_refspecs(), {
                            credentials: @credentials
                        })
                    end
                end
            end

        end
    end
end
