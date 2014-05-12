require_relative 'claw'
require 'test/unit'
require 'rack/test'

class ClawTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  def test_hi
    get '/hi'
    assert_equal 'Hello World!', last_response.body
  end

  def test_edge_will_direct_you_to_link
    EDGE.each do |arch, link|
      get '/edge', 'arch' => arch

      assert_equal 302, last_response.status, "Error requesting: #{arch}"
      assert_equal link, last_response.original_headers['location'], "Could not find: #{arch}"
    end
  end

  def test_edge_will_return_412_when_arch_is_not_passed
    get 'edge'

    assert_equal 412, last_response.status

    assert_match(/invalid 'arch'/i, last_response.body)
  end

  def test_edge_will_return_412_when_passed_invalid_arch
    get 'edge', 'arch' => 'awesomesause'

    assert_equal 412, last_response.status
  end
end
