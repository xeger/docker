$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'docker'

RSpec.configure do |c|
  c.filter_run_including focus: true
end
