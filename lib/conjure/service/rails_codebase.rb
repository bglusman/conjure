module Conjure
  module Service
    class RailsCodebase
      def initialize(host, github_url, branch, app_name, database, rails_environment)
        @github_url = github_url
        @branch = branch
        @app_name = app_name
        @database = database
        @rails_environment = rails_environment
        github_private_key = Conjure.config.file_contents(:private_key_file).gsub("\n", "\\n")
        github_public_key = Conjure.config.file_contents(:public_key_file).gsub("\n", "\\n")
        @image = host.images.create(
          label: "codebase",
          base_image: "ubuntu",
          setup_commands: [
            "apt-get install -y git",
            "mkdir -p /root/.ssh; echo '#{github_private_key}' > /root/.ssh/id_rsa",
            "mkdir -p /root/.ssh; echo '#{github_public_key}' > /root/.ssh/id_rsa.pub",
            "chmod -R go-rwx /root/.ssh",
            "echo 'Host github.com\\n\\tStrictHostKeyChecking no\\n' >> /root/.ssh/config",
          ],
          host_volumes: {"/rails_app" => "/#{app_name}"},
        )
      end

      def database_yml
        {
          @rails_environment => {
            "adapter" => "postgresql",
            "database" => @database.name,
            "encoding" => "utf8",
            "host" => @database.ip_address,
            "username" => "root",
            "template" => "template0",
          }
        }.to_yaml
      end

      def install
        code_checked_out ? fetch_code_updates : checkout_code
        configure_database
        configure_logs
      end

      def code_checked_out
        @image.command("[ -d #{@app_name}/.git ] && echo yes; true").strip == "yes"
      end

      def checkout_code
        Conjure.log "[  repo] Checking out code from git"
        @image.command "git clone -b #{@branch} #{@github_url}"
      end

      def fetch_code_updates
        Conjure.log "[  repo] Fetching code updates from git"
        @image.command "cd #{@app_name}; git reset --hard; git checkout #{@branch}; git pull"
      end

      def configure_database
        Conjure.log "[  repo] Generating database.yml"
        @image.command "echo '#{database_yml}' >/#{@app_name}/config/database.yml"
      end

      def configure_logs
        Conjure.log "[  repo] Configuring application logger"
        setup = 'Rails.logger = Logger.new "#{Rails.root}/log/#{Rails.env}.log"'
        @image.command "echo '#{setup}' >/#{@app_name}/config/initializers/z_conjure_logger.rb"
      end
    end
  end
end
