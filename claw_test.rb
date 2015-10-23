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

  def test_edge_with_arch_redirects
    EDGE_ARCH_TO_FILENAMES.each do |arch, filename|
      get '/edge', 'arch' => arch

      assert_equal 302, last_response.status, "Error requesting: #{arch}"
      assert_equal EDGE_LINK % {file_name: filename}, last_response.original_headers['location'], "Could not find: #{arch}"
    end
  end

  def test_edge_without_arch_returns_412
    get 'edge'

    assert_equal 412, last_response.status
    assert_match(/invalid 'arch'/i, last_response.body)
  end

  def test_edge_with_invalid_arch_returns_412
    get 'edge', 'arch' => 'awesomesause'
    assert_equal 412, last_response.status
  end

  def test_stable_with_release_redirects
    RELEASE_TO_FILENAME.each do |release, filename|
      get '/stable', 'release' => release

      redirect_link = VERSIONED_RELEASE_LINK % {version: STABLE_VERSION, release: filename}
      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal redirect_link, last_response.original_headers['location'], "Could not find: #{release}"
    end
  end

  def test_stable_without_release_returns_412
    get 'stable'

    assert_equal 412, last_response.status
    assert_match(/invalid 'release'/i, last_response.body)
  end

  def test_stable_with_invalid_release_returns_412
    get 'stable', 'release' => 'awesomesause'

    assert_equal 412, last_response.status
  end

  def test_stable_with_release_and_version_redirects
    release = RELEASE_TO_FILENAME.keys.first
    AVAILABLE_VERSIONS.each do |version|
      get 'stable', {'release' => release, 'version' => version}

      redirect_link = VERSIONED_RELEASE_LINK % {version: version, release: RELEASE_TO_FILENAME[release]}
      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal redirect_link, last_response.original_headers['location'], "Could not find: #{release}"
    end
  end

  def test_stable_with_release_and_invalid_version_returns_412
    version = 'potato'
    release = RELEASE_TO_FILENAME.keys.first
    get 'stable', {'release' => release, 'version' => version}

    assert_equal 412, last_response.status
  end

  def test_stable_with_http_accept_language_redirects
    header 'Accept-Language', 'da, en-gb;q=0.8, en;q=0.7'
    get 'stable', {'release' => 'windows64', 'version' => '6.12.4'}

    assert_equal 302, last_response.status
  end
end
