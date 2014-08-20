metadata :name => "puppetenv",
         :description => "Simple tool to update puppet dynamic environments mastered in git",
         :author => "Ben Roberts",
         :license => "MIT",
         :version => "0.1",
         :url => "https://github.com/optiz0r/mcollective-puppetenv-agent",
         :timeout => 60

action "list", :description => "Lists all dynamic environments currently available" do
    output :environments,
           :description => "List of dynamic environments",
           :display_as  => "Environments"
end

action "add", :description => "Adds a new dynamic environment from an existing git branch" do
    input :environment,
          :prompt      => "Environment name",
          :description => "Name of the new environment (matching the git branch)",
          :type        => :string,
          :validation  => '^[a-zA-Z0-9_]+$',
          :optional    => false,
          :maxlength   => 30
    output :status,
           :description => "Status of the operation",
           :display_as  => "Status"
end

action "update", :description => "Update an existing environment to match the git branch" do
    input :environment,
          :prompt => "Environment name",
          :description => "Name of the existing environment to update (matching the git branch",
          :type        => :string,
          :validation  => '^[a-zA-Z0-9_]+$',
          :optional    => false,
          :maxlength   => 30
end

action "rm", :description => "Removes a new dynamic environment for a deleted branch" do
    input :environment,
          :prompt      => "Environment name",
          :description => "Name of the new environment (matching the git branch)",
          :type        => :string,
          :validation  => '^[a-zA-Z0-9_]+$',
          :optional    => false,
          :maxlength   => 30
end

action "update-all", :description => "Updates all dynamic environments to match git" do
    output :added,
           :description => "List of newly added dynamic environments",
           :display_as  => "Added"

    output :updated,
           :description => "List of updated dynamic environments",
           :display_as  => "Updated"

    output :removed,
           :description => "List of removed dynamic environments",
           :display_as  => "Removed"

    output :rejected,
           :description => "List of git branches which were unsuitable for use as dynamic environments",
           :display_as  => "Rejected"
end
