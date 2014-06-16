ENV['RACK_ENV'] = 'test'
ENV['GA_TRACKING_ID'] = 'dummy_id'
ENV['GA_DOMAIN'] = 'dummy.domain.example.com'

require_relative 'claw'
require 'test/unit'
require 'rack/test'

class ClawTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Claw
  end

  def test_ping
    get '/ping'
    assert_equal 'pong', last_response.body
  end

  def test_edge_will_direct_you_to_link
    EDGE_ARCH_TO_FILENAMES.each do |arch, filename|
      get '/edge', 'arch' => arch

      assert_equal 302, last_response.status, "Error requesting: #{arch}"
      assert_equal EDGE_LINK % {file_name: filename}, last_response.original_headers['location'], "Could not find: #{arch}"
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

  def test_stable_will_direct_you_to_link
    STABLE_RELEASE_TO_FILENAME.each do |release, filename|
      get '/stable', 'release' => release

      redirect_link = STABLE_LINK % {version: LATEST_STABLE_VERSION, release: filename}
      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal redirect_link, last_response.original_headers['location'], "Could not find: #{release}"
    end
  end

  def test_stable_will_return_412_when_release_is_not_passed
    get 'stable'

    assert_equal 412, last_response.status

    assert_match(/invalid 'release'/i, last_response.body)
  end

  def test_stable_will_return_412_when_passed_invalid_release
    get 'stable', 'release' => 'awesomesause'

    assert_equal 412, last_response.status
  end

  def test_stable_will_redirect_to_correct_version_when_passed
    release = STABLE_RELEASE_TO_FILENAME.keys.first
    STABLE_VERSIONS.each do |version|
      get 'stable', {'release' => release, 'version' => version}

      redirect_link = STABLE_LINK % {version: version, release: STABLE_RELEASE_TO_FILENAME[release]}
      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal redirect_link, last_response.original_headers['location'], "Could not find: #{release}"
    end
  end

  def test_stable_will_error_when_passed_invalid_version
    version = 'potato'
    release = STABLE_RELEASE_TO_FILENAME.keys.first
    get 'stable', {'release' => release, 'version' => version}

    assert_equal 412, last_response.status
  end
end
