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

  def test_stable_with_release_and_without_version_redirects_to_latest
    {
      "debian32" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_i686.deb",
      "debian64" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_x86-64.deb",
      "redhat32" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_i686.rpm",
      "redhat64" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_x86-64.rpm",
      "macosx64" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_osx.pkg",
      "windows32" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_win32.zip",
      "windows64" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_winx64.zip",
      "linux32-binary" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli_#{STABLE_VERSION}_linux_i686.tgz",
      "linux64-binary" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli_#{STABLE_VERSION}_linux_x86-64.tgz",
      "macosx64-binary" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli_#{STABLE_VERSION}_osx.tgz",
      "windows32-exe" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli_#{STABLE_VERSION}_win32.zip",
      "windows64-exe" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v#{STABLE_VERSION}/cf-cli_#{STABLE_VERSION}_winx64.zip",
    }.each { |release, expected_link|
      get '/stable', 'release' => release

      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal expected_link, last_response.original_headers['location'], "Could not find: #{release}"
    }
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
    {
      "debian32" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli-installer_6.13.0_i686.deb",
      "debian64" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli-installer_6.13.0_x86-64.deb",
      "redhat32" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli-installer_6.13.0_i686.rpm",
      "redhat64" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli-installer_6.13.0_x86-64.rpm",
      "macosx64" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli-installer_6.13.0_osx.pkg",
      "windows32" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli-installer_6.13.0_win32.zip",
      "windows64" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli-installer_6.13.0_winx64.zip",
      "linux32-binary" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli_6.13.0_linux_i686.tgz",
      "linux64-binary" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli_6.13.0_linux_x86-64.tgz",
      "macosx64-binary" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli_6.13.0_osx.tgz",
      "windows32-exe" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli_6.13.0_win32.zip",
      "windows64-exe" => "http://go-cli.s3-website-us-east-1.amazonaws.com/releases/v6.13.0/cf-cli_6.13.0_winx64.zip",
    }.each { |release, expected_link|
      get '/stable', 'release' => release, 'version' => '6.13.0'

      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal expected_link, last_response.original_headers['location'], "Could not find: #{release}"
    }
  end

  def test_stable_with_release_and_invalid_version_returns_412
    get 'stable', {'release' => 'debian32', 'version' => 'potato'}

    assert_equal 412, last_response.status
  end

  def test_stable_with_http_accept_language_redirects
    header 'Accept-Language', 'da, en-gb;q=0.8, en;q=0.7'
    get 'stable', {'release' => 'windows64', 'version' => '6.12.4'}

    assert_equal 302, last_response.status
  end
end
