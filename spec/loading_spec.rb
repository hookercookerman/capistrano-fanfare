require 'minitest/autorun'
require 'capistrano/fanfare'

describe Capistrano::Fanfare do
  before do
    @config = Capistrano::Configuration.new
    @config.load_paths << File.join(File.dirname(__FILE__), "fixtures")
    @orig_config = Capistrano::Configuration.instance
    Capistrano::Configuration.instance = @config
  end

  after do
    Capistrano::Configuration.instance = @orig_config
  end

  it 'loads a fanfare capistrano recipe' do
    @config.load 'fanfare/bark'

    @config.find_and_execute_task("bark").must_equal "ruff ruff"
    @config.fetch(:message).must_equal "ruff ruff"
  end

  it 'adds #fanfare_recipe onto Capistrano::Configuration' do
    @config.must_respond_to :fanfare_recipe
  end
end
