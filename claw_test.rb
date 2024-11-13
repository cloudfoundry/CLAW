# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
ENV['GPG_KEY'] = 'dummy-key'
ENV['AVAILABLE_VERSIONS'] = '["6.12.4", "6.13.0", "7.0.0-beta.24", "8.0.0", "8.0.1"]'
ENV['CURRENT_MAJOR_VERSION'] = 'v7'
ENV['ENVIRONMENT'] = 'prod'

require_relative 'claw'
require 'test/unit'
require 'rack/test'

RELEASE_LINK = 'https://github.com/cloudfoundry/cli/releases/download/v%{version}/%{release}'

EDGE_LINK = 'https://github.com/cloudfoundry/cli/releases/latest/%{file_name}'

EDGE_ARCH_TO_V8_FILENAMES = {
  'linux32' => 'cf8-cli_edge_linux_i686.tgz',
  'linux64' => 'cf8-cli_edge_linux_x86-64.tgz',
  'linuxarm64' => 'cf8-cli_edge_linux_arm64.tgz',
  'macosx64' => 'cf8-cli_edge_osx.tgz',
  'macosarm' => 'cf8-cli_edge_macosarm.tgz',
  'windows32' => 'cf8-cli_edge_win32.zip',
  'windows64' => 'cf8-cli_edge_winx64.zip'
}.freeze

class ClawTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Claw
  end

  def test_ping
    get '/ping'
    assert_equal 'pong', last_response.body
  end

  # STABLE

  def test_stable_with_release_and_without_version_redirects_to_current_major_version
    ENV['CURRENT_MAJOR_VERSION'] = 'v6'
    {
      'debian32' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli-installer_#{STABLE_V6_VERSION}_i686.deb",
      'debian64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli-installer_#{STABLE_V6_VERSION}_x86-64.deb",
      'redhat32' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli-installer_#{STABLE_V6_VERSION}_i686.rpm",
      'redhat64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli-installer_#{STABLE_V6_VERSION}_x86-64.rpm",
      'macosx64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli-installer_#{STABLE_V6_VERSION}_osx.pkg",
      'windows32' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli-installer_#{STABLE_V6_VERSION}_win32.zip",
      'windows64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli-installer_#{STABLE_V6_VERSION}_winx64.zip",
      'linux32-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli_#{STABLE_V6_VERSION}_linux_i686.tgz",
      'linux64-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli_#{STABLE_V6_VERSION}_linux_x86-64.tgz",
      'macosx64-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli_#{STABLE_V6_VERSION}_osx.tgz",
      'windows32-exe' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli_#{STABLE_V6_VERSION}_win32.zip",
      'windows64-exe' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V6_VERSION}/cf-cli_#{STABLE_V6_VERSION}_winx64.zip"
    }.each do |release, expected_link|
      get '/stable', 'release' => release

      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal expected_link, last_response.original_headers['location'], "Could not find: #{release}"
    end

    ENV['CURRENT_MAJOR_VERSION'] = 'v7'
    {
      'debian32' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli-installer_#{STABLE_V7_VERSION}_i686.deb",
      'debian64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli-installer_#{STABLE_V7_VERSION}_x86-64.deb",
      'debianarm64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli-installer_#{STABLE_V7_VERSION}_arm64.deb",
      'redhat32' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli-installer_#{STABLE_V7_VERSION}_i686.rpm",
      'redhat64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli-installer_#{STABLE_V7_VERSION}_x86-64.rpm",
      'redhataarch64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli-installer_#{STABLE_V7_VERSION}_aarch64.rpm",
      'macosx64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli-installer_#{STABLE_V7_VERSION}_osx.pkg",
      'macosarm' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli-installer_#{STABLE_V7_VERSION}_macosarm.pkg",
      'windows32' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli-installer_#{STABLE_V7_VERSION}_win32.zip",
      'windows64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli-installer_#{STABLE_V7_VERSION}_winx64.zip",
      'linux32-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli_#{STABLE_V7_VERSION}_linux_i686.tgz",
      'linux64-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli_#{STABLE_V7_VERSION}_linux_x86-64.tgz",
      'linuxarm64-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli_#{STABLE_V7_VERSION}_linux_arm64.tgz",
      'macosx64-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli_#{STABLE_V7_VERSION}_osx.tgz",
      'macosarm-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli_#{STABLE_V7_VERSION}_macosarm.tgz",
      'windows32-exe' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli_#{STABLE_V7_VERSION}_win32.zip",
      'windows64-exe' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V7_VERSION}/cf7-cli_#{STABLE_V7_VERSION}_winx64.zip"
    }.each do |release, expected_link|
      get '/stable', 'release' => release

      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal expected_link, last_response.original_headers['location'], "Could not find: #{release}"
    end

    ENV['CURRENT_MAJOR_VERSION'] = 'v8'
    {
      'debian32' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli-installer_#{STABLE_V8_VERSION}_i686.deb",
      'debian64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli-installer_#{STABLE_V8_VERSION}_x86-64.deb",
      'debianarm64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli-installer_#{STABLE_V8_VERSION}_arm64.deb",
      'redhat32' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli-installer_#{STABLE_V8_VERSION}_i686.rpm",
      'redhat64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli-installer_#{STABLE_V8_VERSION}_x86-64.rpm",
      'redhataarch64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli-installer_#{STABLE_V8_VERSION}_aarch64.rpm",
      'macosx64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli-installer_#{STABLE_V8_VERSION}_osx.pkg",
      'macosarm' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli-installer_#{STABLE_V8_VERSION}_macosarm.pkg",
      'windows32' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli-installer_#{STABLE_V8_VERSION}_win32.zip",
      'windows64' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli-installer_#{STABLE_V8_VERSION}_winx64.zip",
      'linux32-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli_#{STABLE_V8_VERSION}_linux_i686.tgz",
      'linux64-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli_#{STABLE_V8_VERSION}_linux_x86-64.tgz",
      'linuxarm64-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli_#{STABLE_V8_VERSION}_linux_arm64.tgz",
      'macosx64-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli_#{STABLE_V8_VERSION}_osx.tgz",
      'macosarm-binary' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli_#{STABLE_V8_VERSION}_macosarm.tgz",
      'windows32-exe' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli_#{STABLE_V8_VERSION}_win32.zip",
      'windows64-exe' => "https://github.com/cloudfoundry/cli/releases/download/v#{STABLE_V8_VERSION}/cf8-cli_#{STABLE_V8_VERSION}_winx64.zip"
    }.each do |release, expected_link|
      get '/stable', 'release' => release

      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal expected_link, last_response.original_headers['location'], "Could not find: #{release}"
    end
  end

  def test_stable_with_v6_redirects_to_latest_v6
    get 'stable', 'release' => 'macosx64-binary', 'version' => 'v6'

    assert_equal 302, last_response.status
    assert_equal 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli_6.13.0_osx.tgz', last_response.original_headers['location']
  end

  def test_stable_with_v7_redirects_to_latest_v7
    get 'stable', 'release' => 'macosx64-binary', 'version' => 'v7'

    assert_equal 302, last_response.status
    assert_equal 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli_7.0.0-beta.24_osx.tgz', last_response.original_headers['location']
  end

  def test_stable_with_v8_redirects_to_latest_v8
    get 'stable', 'release' => 'macosx64-binary', 'version' => 'v8'

    assert_equal 302, last_response.status
    assert_equal 'https://github.com/cloudfoundry/cli/releases/download/v8.0.1/cf8-cli_8.0.1_osx.tgz', last_response.original_headers['location']
  end


  def test_stable_with_explicit_v6_version_redirects
    {
      'debian32' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli-installer_6.13.0_i686.deb',
      'debian64' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli-installer_6.13.0_x86-64.deb',
      'redhat32' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli-installer_6.13.0_i686.rpm',
      'redhat64' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli-installer_6.13.0_x86-64.rpm',
      'macosx64' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli-installer_6.13.0_osx.pkg',
      'windows32' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli-installer_6.13.0_win32.zip',
      'windows64' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli-installer_6.13.0_winx64.zip',
      'linux32-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli_6.13.0_linux_i686.tgz',
      'linux64-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli_6.13.0_linux_x86-64.tgz',
      'macosx64-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli_6.13.0_osx.tgz',
      'windows32-exe' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli_6.13.0_win32.zip',
      'windows64-exe' => 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli_6.13.0_winx64.zip'
    }.each do |release, expected_link|
      get '/stable', 'release' => release, 'version' => '6.13.0'

      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal expected_link, last_response.original_headers['location'], "Could not find: #{release}"
    end
  end

  def test_stable_with_explicit_v7_version_redirects
    {
      'debian32' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_i686.deb',
      'debian64' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_x86-64.deb',
      'debianarm64' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_arm64.deb',
      'redhat32' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_i686.rpm',
      'redhat64' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_x86-64.rpm',
      'redhataarch64' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_aarch64.rpm',
      'macosx64' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_osx.pkg',
      'macosarm' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_macosarm.pkg',
      'windows32' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_win32.zip',
      'windows64' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_winx64.zip',
      'linux32-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli_7.0.0-beta.24_linux_i686.tgz',
      'linux64-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli_7.0.0-beta.24_linux_x86-64.tgz',
      'linuxarm64-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli_7.0.0-beta.24_linux_arm64.tgz',
      'macosx64-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli_7.0.0-beta.24_osx.tgz',
      'macosarm-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli_7.0.0-beta.24_macosarm.tgz',
      'windows32-exe' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli_7.0.0-beta.24_win32.zip',
      'windows64-exe' => 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli_7.0.0-beta.24_winx64.zip'
    }.each do |release, expected_link|
      get '/stable', 'release' => release, 'version' => '7.0.0-beta.24'

      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal expected_link, last_response.original_headers['location'], "Could not find: #{release}"
    end
  end

  def test_stable_with_explicit_v8_version_redirects
    {
      'debian32' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_i686.deb',
      'debian64' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_x86-64.deb',
      'debianarm64' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_arm64.deb',
      'redhat32' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_i686.rpm',
      'redhat64' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_x86-64.rpm',
      'redhataarch64' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_aarch64.rpm',
      'macosx64' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_osx.pkg',
      'macosarm' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_macosarm.pkg',
      'windows32' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_win32.zip',
      'windows64' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_winx64.zip',
      'linux32-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli_8.0.0_linux_i686.tgz',
      'linux64-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli_8.0.0_linux_x86-64.tgz',
      'linuxarm64-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli_8.0.0_linux_arm64.tgz',
      'macosx64-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli_8.0.0_osx.tgz',
      'macosarm-binary' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli_8.0.0_macosarm.tgz',
      'windows32-exe' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli_8.0.0_win32.zip',
      'windows64-exe' => 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli_8.0.0_winx64.zip'
    }.each do |release, expected_link|
      get '/stable', 'release' => release, 'version' => '8.0.0'

      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal expected_link, last_response.original_headers['location'], "Could not find: #{release}"
    end
  end


  def test_stable_without_release_returns_412
    get 'stable'
    assert_equal 412, last_response.status
    assert_match(/invalid 'release'/i, last_response.body)

    get 'stable', 'version' => '6.13.0'
    assert_equal 412, last_response.status
    assert_match(/invalid 'release'/i, last_response.body)

    get 'stable', 'version' => '7.0.0'
    assert_equal 412, last_response.status
    assert_match(/invalid 'release'/i, last_response.body)

    get 'stable', 'version' => '8.0.0'
    assert_equal 412, last_response.status
    assert_match(/invalid 'release'/i, last_response.body)
  end

  def test_stable_with_invalid_release_returns_412
    get 'stable', 'release' => 'awesomesause'
    assert_equal 412, last_response.status

    get 'stable', 'release' => 'awesomesause', 'version' => '6.13.0'
    assert_equal 412, last_response.status

    get 'stable', 'release' => 'awesomesause', 'version' => '7.0.0'
    assert_equal 412, last_response.status

    get 'stable', 'release' => 'awesomesause', 'version' => '8.0.0'
    assert_equal 412, last_response.status
  end

  def test_stable_with_release_and_invalid_version_returns_412
    get 'stable', 'release' => 'debian32', 'version' => 'potato'
    assert_equal 412, last_response.status
  end

  def test_stable_with_http_accept_language_redirects
    header 'Accept-Language', 'da, en-gb;q=0.8, en;q=0.7'
    get 'stable', 'release' => 'windows64', 'version' => '6.12.4'

    assert_equal 302, last_response.status
  end

  # HOMEBREW

  def test_valid_homebrew_url_redirects_to_osx_tgz
    get '/homebrew?arch=macosx64&version=6.12.4'

    assert_equal 302, last_response.status
    assert_equal format(RELEASE_LINK, version: '6.12.4', release: 'cf-cli_6.12.4_osx.tgz'), last_response.original_headers['location']
  end

  def test_invalid_homebrew_url_returns_412
    get '/homebrew?arch=macosx64&version=0.0.0'
    assert_equal 412, last_response.status
  end

  def test_unavailable_homebrew_url_returns_412
    get '/homebrew?arch=macosx64&version=9.0.0'
    assert_equal 412, last_response.status
  end

  def test_valid_homebrew_url_redirects_to_osx_tgz_v7
    get '/homebrew?arch=macosx64&version=7.0.0-beta.24'

    assert_equal 302, last_response.status
    assert_equal format(RELEASE_LINK, version: '7.0.0-beta.24', release: 'cf7-cli_7.0.0-beta.24_osx.tgz'), last_response.original_headers['location']
  end

  def test_valid_homebrew_url_redirects_to_osx_tgz_v8
    get '/homebrew?arch=macosx64&version=8.0.0'

    assert_equal 302, last_response.status
    assert_equal format(RELEASE_LINK, version: '8.0.0', release: 'cf8-cli_8.0.0_osx.tgz'), last_response.original_headers['location']
  end

  #ARM
  def test_valid_homebrew_url_redirects_to_arm_tgz_v7
    get '/homebrew?arch=macosarm&version=7.0.0-beta.24'

    assert_equal 302, last_response.status
    assert_equal format(RELEASE_LINK, version: '7.0.0-beta.24', release: 'cf7-cli_7.0.0-beta.24_macosarm.tgz'), last_response.original_headers['location']
  end

  def test_valid_homebrew_url_redirects_to_arm_tgz_v8
    get '/homebrew?arch=macosarm&version=8.0.1'

    assert_equal 302, last_response.status
    assert_equal format(RELEASE_LINK, version: '8.0.1', release: 'cf8-cli_8.0.1_macosarm.tgz'), last_response.original_headers['location']
  end
  # DEBIAN

  def test_debian_dists_redirect
    get '/debian/dists/foo'

    assert_equal 302, last_response.status
    assert_equal File.join(APT_REPO, 'dists/foo'), last_response.original_headers['location']
  end

  def test_debian_pool_redirect
    get '/debian/pool/cf_6.13.0_amd64.deb'
    expected_link = 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf_6.13.0_amd64.deb'
    assert_equal 302, last_response.status
    assert_equal expected_link, last_response.original_headers['location']
  end

  def test_debian_pool_redirect_7
    get '/debian/pool/cf7-cli-installer_7.0.0-beta.24_x86-64.deb'
    expected_link = 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_x86-64.deb'
    assert_equal 302, last_response.status
    assert_equal expected_link, last_response.original_headers['location']
  end

  def test_debian_pool_redirect_8
    get '/debian/pool/cf8-cli-installer_8.0.0_x86-64.deb'
    expected_link = 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_x86-64.deb'
    assert_equal 302, last_response.status
    assert_equal expected_link, last_response.original_headers['location']
  end

  # FEDORA

  def test_fedora_repodata_redirect
    get '/fedora/repodata/foo'

    assert_equal 302, last_response.status
    assert_equal File.join(RPM_REPO, 'repodata/foo'), last_response.original_headers['location']
  end

  def test_fedora_repofile_redirect
    get '/fedora/cloudfoundry-cli.repo'

    assert_equal 302, last_response.status
    assert_equal File.join(RPM_REPO, 'cloudfoundry-cli.repo'), last_response.original_headers['location']
  end

  def test_fedora_releases_redirect
    get 'fedora/releases/cf_6.13.0_amd64.rpm'
    expected_link = 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf_6.13.0_amd64.rpm'
    assert_equal 302, last_response.status
    assert_equal expected_link, last_response.original_headers['location']
  end

  def test_fedora_releases_redirect_v7
    get 'fedora/releases/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_x86-64.rpm'
    expected_link = 'https://github.com/cloudfoundry/cli/releases/download/v7.0.0-beta.24/cf7-cli-installer_7.0.0-beta.24_x86-64.rpm'
    assert_equal 302, last_response.status
    assert_equal expected_link, last_response.original_headers['location']
  end

  def test_fedora_releases_redirect_v8
    get 'fedora/releases/v8.0.0/cf8-cli-installer_8.0.0_x86-64.rpm'
    expected_link = 'https://github.com/cloudfoundry/cli/releases/download/v8.0.0/cf8-cli-installer_8.0.0_x86-64.rpm'
    assert_equal 302, last_response.status
    assert_equal expected_link, last_response.original_headers['location']
  end

  def test_fedora_releases_redirect_with_linux_in_filename
    get 'fedora/releases/v6.13.0/cf-cli-installer_6.13.0_linux_x86-64.rpm'
    expected_link = 'https://github.com/cloudfoundry/cli/releases/download/v6.13.0/cf-cli-installer_6.13.0_linux_x86-64.rpm'
    assert_equal 302, last_response.status
    assert_equal expected_link, last_response.original_headers['location']
  end

  # GPG KEY

  def test_gpg_key_debian
    get '/debian/cli.cloudfoundry.org.key'

    assert_equal 200, last_response.status
    assert_equal last_response.body, 'dummy-key'
    assert_equal last_response.header['Content-Type'], 'text/plain;charset=utf-8'
  end

  def test_gpg_key_redhat
    get '/fedora/cli.cloudfoundry.org.key'

    assert_equal 200, last_response.status
    assert_equal last_response.body, 'dummy-key'
    assert_equal last_response.header['Content-Type'], 'text/plain;charset=utf-8'
  end

end
