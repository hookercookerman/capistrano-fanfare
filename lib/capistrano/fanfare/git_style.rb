require 'capistrano'
require 'capistrano/recipes/deploy/strategy/git_style'

module Capistrano::Fanfare::GitStyle
  def self.load_into(configuration)
    configuration.load do
      set :scm,             :git
      set :deploy_via,      :git_style
      set(:release_name)    { %{#{Time.now.utc.strftime("%Y%m%d%H%M%S")}-#{real_revision}} }
      set(:release_path)    { current_path }
      set(:current_release) { current_path }
      set(:latest_release)  { current_path }

      set(:current_revision) {
        capture("cd #{current_path} && git rev-parse HEAD",
                :except => { :no_release => true }).chomp }
      set(:latest_revision) {
        last_release_dir = releases.length > 0 ? File.join(releases_path, releases.last) : nil
        capture("basename #{last_release_dir} | cut -d - -f 2",
                :except => { :no_release => true }).chomp }
      set(:previous_revision) {
        capture("basename #{previous_release} | cut -d - -f 2",
                :except => { :no_release => true }).chomp if previous_release }

      # =========================================================================
      # These are the tasks that are available to help with deploying web apps.
      # You can have cap give you a summary of them with `cap -T'.
      # =========================================================================

      namespace :deploy do
        desc <<-DESC
          Copies your project to the remote servers. This is the first stage \
          of any deployment; moving your updated code and assets to the deployment \
          servers. You will rarely call this task directly, however; instead, you \
          should call the `deploy' task (to do a complete deploy) or the `update' \
          task (if you want to perform the `restart' task separately).

          You will need to make sure you set the :scm variable to the source \
          control software you are using (it defaults to :subversion), and the \
          :deploy_via variable to the strategy you want to use to deploy (it \
          defaults to :checkout).

          [NOTE] This overrides the capistrano default by removing the \
          on_rollback logic since previous release checkouts don't exist.
        DESC
        task :update_code, :except => { :no_release => true } do
          strategy.deploy!
          finalize_update
        end

        desc <<-DESC
          [internal] No-op for git-based deployments.

          [NOTE] This overides the capistrano default since there is no need for a
          symlink farm.
        DESC
        task :create_symlink, :except => { :no_release => true } do
        end

        namespace :rollback do
          desc <<-DESC
            [internal] Updates git HEAD to the last deployed commit.
            This is called by the rollback sequence, and should rarely (if
            ever) need to be called directly.
          DESC
          task :revision, :except => { :no_release => true } do
            if previous_release
              set :branch, previous_revision
              update_code
            else
              raise "could not rollback the code because there is no prior release"
            end
          end

          desc <<-DESC
            [internal] No-op for git-based deployments.
            This is called by the rollback sequence, and should rarely
            (if ever) need to be called directly.
          DESC
          task :cleanup, :roles => [:app, :web, :db], :except => { :no_release => true } do
            run %{if [ `(cd #{current_path} && git rev-parse HEAD)` != `#{latest_revision}` ]; then rm -rf #{current_release}; fi}
          end
        end

      end
    end
  end
end

if Capistrano::Configuration.instance
  Capistrano::Fanfare::GitStyle.load_into(Capistrano::Configuration.instance)
end
