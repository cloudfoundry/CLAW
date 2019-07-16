# frozen_string_literal: true

ENV['RACK_ENV'] = 'test'
ENV['GA_TRACKING_ID'] = 'dummy_id'
ENV['GA_DOMAIN'] = 'dummy.domain.example.com'
ENV['GPG_KEY'] = 'dummy-key'
ENV['AVAILABLE_VERSIONS'] = '6.12.4,6.13.0,7.0.0-beta.1'

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
      assert_equal format(EDGE_LINK, file_name: filename), last_response.original_headers['location'], "Could not find: #{arch}"
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

  def test_edge_with_arch_redirects_v7
    EDGE_ARCH_TO_V7_FILENAMES.each do |arch, filename|
      get '/edge', 'arch' => arch, 'version' => 'v7'

      assert_equal 302, last_response.status, "Error requesting: #{arch}"
      assert_equal format(EDGE_LINK_V7, file_name: filename), last_response.original_headers['location'], "Could not find: #{arch}"
    end
  end

  def test_edge_without_arch_returns_412_v7
    get 'edge', 'version' => 'v7'

    assert_equal 412, last_response.status
    assert_match(/invalid 'arch'/i, last_response.body)
  end

  def test_edge_with_invalid_arch_returns_412_v7
    get 'edge', 'arch' => 'awesomesause', 'version' => 'v7'
    assert_equal 412, last_response.status
  end

  def test_stable_with_release_and_without_version_redirects_to_latest
    {
      'debian32' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_i686.deb",
      'debian64' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_x86-64.deb",
      'redhat32' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_i686.rpm",
      'redhat64' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_x86-64.rpm",
      'macosx64' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_osx.pkg",
      'windows32' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_win32.zip",
      'windows64' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli-installer_#{STABLE_VERSION}_winx64.zip",
      'linux32-binary' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli_#{STABLE_VERSION}_linux_i686.tgz",
      'linux64-binary' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli_#{STABLE_VERSION}_linux_x86-64.tgz",
      'macosx64-binary' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli_#{STABLE_VERSION}_osx.tgz",
      'windows32-exe' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli_#{STABLE_VERSION}_win32.zip",
      'windows64-exe' => "https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v#{STABLE_VERSION}/cf-cli_#{STABLE_VERSION}_winx64.zip"
    }.each do |release, expected_link|
      get '/stable', 'release' => release

      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal expected_link, last_response.original_headers['location'], "Could not find: #{release}"
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
    {
      'debian32' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli-installer_6.13.0_i686.deb',
      'debian64' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli-installer_6.13.0_x86-64.deb',
      'redhat32' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli-installer_6.13.0_i686.rpm',
      'redhat64' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli-installer_6.13.0_x86-64.rpm',
      'macosx64' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli-installer_6.13.0_osx.pkg',
      'windows32' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli-installer_6.13.0_win32.zip',
      'windows64' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli-installer_6.13.0_winx64.zip',
      'linux32-binary' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli_6.13.0_linux_i686.tgz',
      'linux64-binary' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli_6.13.0_linux_x86-64.tgz',
      'macosx64-binary' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli_6.13.0_osx.tgz',
      'windows32-exe' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli_6.13.0_win32.zip',
      'windows64-exe' => 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli_6.13.0_winx64.zip'
    }.each do |release, expected_link|
      get '/stable', 'release' => release, 'version' => '6.13.0'

      assert_equal 302, last_response.status, "Error requesting: #{release}"
      assert_equal expected_link, last_response.original_headers['location'], "Could not find: #{release}"
    end
  end

  def test_stable_with_release_and_invalid_version_returns_412
    get 'stable', 'release' => 'debian32', 'version' => 'potato'

    assert_equal 412, last_response.status
  end

  #   test_stable_without_version_does_not_accidentally_ship_v7
  def test_stable_without_version_redirects_to_v6
    get 'stable', 'release' => 'macosx64-binary'

    assert_equal 302, last_response.status
    assert_equal 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli_6.13.0_osx.tgz', last_response.original_headers['location']
  end

  def test_stable_with_v7_redirects_to_latest_v7
    get 'stable', 'release' => 'macosx64-binary', 'version' => 'v7'

    assert_equal 302, last_response.status
    assert_equal 'https://s3-us-west-1.amazonaws.com/v7-cf-cli-releases/releases/v7.0.0-beta.1/cf-cli_7.0.0-beta.1_osx.tgz', last_response.original_headers['location']
  end

  def test_stable_with_explicit_v7_version_redirects
    get 'stable', 'release' => 'macosx64-binary', 'version' => '7.0.0-beta.1'

    assert_equal 302, last_response.status
    assert_equal 'https://s3-us-west-1.amazonaws.com/v7-cf-cli-releases/releases/v7.0.0-beta.1/cf-cli_7.0.0-beta.1_osx.tgz', last_response.original_headers['location']
  end

  def test_stable_with_http_accept_language_redirects
    header 'Accept-Language', 'da, en-gb;q=0.8, en;q=0.7'
    get 'stable', 'release' => 'windows64', 'version' => '6.12.4'

    assert_equal 302, last_response.status
  end

  def test_valid_homebrew_url_redirects_to_osx_tgz
    get '/homebrew/cf-6.12.4.tgz'

    assert_equal 302, last_response.status
    assert_equal format(VERSIONED_V6_RELEASE_LINK, version: '6.12.4', release: 'cf-cli_6.12.4_osx.tgz'), last_response.original_headers['location']
  end

  def test_invalid_homebrew_url_returns_412
    get '/homebrew/cf-garbage.tgz'
    assert_equal 412, last_response.status
  end

  def test_unavailable_homebrew_url_returns_412
    get '/homebrew/cf-9.0.0.tgz'
    assert_equal 412, last_response.status
  end

  def test_valid_homebrew_url_redirects_to_osx_tgz_v7
    get '/homebrew/cf-7.0.0-beta.1.tgz'

    assert_equal 302, last_response.status
    assert_equal format(VERSIONED_V7_RELEASE_LINK, version: '7.0.0-beta.1', release: 'cf-cli_7.0.0-beta.1_osx.tgz'), last_response.original_headers['location']
  end

  def test_debian_dists_redirect
    get '/debian/dists/foo'

    assert_equal 302, last_response.status
    assert_equal File.join(APT_REPO, 'dists/foo'), last_response.original_headers['location']
  end

  def test_debian_pool_redirect
    get '/debian/pool/cf_6.13.0_amd64.deb'
    expected_link = 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf_6.13.0_amd64.deb'
    assert_equal 302, last_response.status
    assert_equal expected_link, last_response.original_headers['location']
  end

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
    expected_link = 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf_6.13.0_amd64.rpm'
    assert_equal 302, last_response.status
    assert_equal expected_link, last_response.original_headers['location']
  end

  def test_fedora_releases_redirect_with_linux_in_filename
    get 'fedora/releases/v6.13.0/cf-cli-installer_6.13.0_linux_x86-64.rpm'
    expected_link = 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v6.13.0/cf-cli-installer_6.13.0_linux_x86-64.rpm'
    assert_equal 302, last_response.status
    assert_equal expected_link, last_response.original_headers['location']
  end

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
