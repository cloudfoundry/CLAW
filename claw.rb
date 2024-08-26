# frozen_string_literal: true

require 'sinatra'
require 'gabba'
require 'semantic'
require 'json'

RELEASE_NAMES = %w[
  debian32
  debian64
  debianarm64
  redhat32
  redhat64
  redhataarch64
  macosx64
  macosarm
  windows32
  windows64
  linux32-binary
  linux64-binary
  linuxarm64-binary
  macosx64-binary
  macosarm-binary
  windows32-exe
  windows64-exe
].freeze

EDGE_ARCHITECTURES = %w[
  linux32
  linux64
  linuxarm64
  macosx64
  macosarm
  windows32
  windows64
].freeze

SUPPORTED_CLI_VERSIONS = [
  'v6',
  'v7',
  'v8'
].freeze

AVAILABLE_VERSIONS = JSON.parse(ENV['AVAILABLE_VERSIONS'])

STABLE_V6_VERSION = AVAILABLE_VERSIONS
                    .map { |version| Semantic::Version.new(version) }
                    .select { |version| version.major == 6 }
                    .last
                    .to_s

STABLE_V7_VERSION = AVAILABLE_VERSIONS
                    .map { |version| Semantic::Version.new(version) }
                    .select { |version| version.major == 7 }
                    .max
                    .to_s

STABLE_V8_VERSION = AVAILABLE_VERSIONS
                    .map { |version| Semantic::Version.new(version) }
                    .select { |version| version.major == 8 }
                    .max
                    .to_s

if ENV['ENVIRONMENT'] == "prod"
  APT_REPO = 'https://cf-cli-debian-repo.s3.amazonaws.com/'
  RPM_REPO = 'https://cf-cli-rpm-repo.s3.amazonaws.com/'
else
  APT_REPO = 'https://cf-cli-dev.s3.amazonaws.com/cf-cli-debian-repo'
  RPM_REPO = 'https://cf-cli-dev.s3.amazonaws.com/cf-cli-rpm-repo'
end

unless ENV.key?('GPG_KEY')
  puts 'Expected a GPG_KEY env var but it was not set'
  exit 1
end

unless ENV.key?('AVAILABLE_VERSIONS')
  puts 'AVAILABLE_VERSIONS not set, please set it before proceeding.'
  exit 1
end

unless ENV.key?('CURRENT_MAJOR_VERSION')
  puts 'CURRENT_MAJOR_VERSION not set, please set it before proceeding.'
  exit 1
end

unless SUPPORTED_CLI_VERSIONS.include?(ENV['CURRENT_MAJOR_VERSION'])
  puts "CURRENT_MAJOR_VERSION is set as an invalid version, only #{SUPPORTED_CLI_VERSIONS.join(', ')} are supported."
  exit 1
end

class Claw < Sinatra::Base
  get '/ping' do
    'pong'
  end

  get /\/(debian|fedora)\/cli\.cloudfoundry\.org\.key/ do
    content_type :text
    ENV['GPG_KEY']
  end

  get '/edge' do
    redirect_link = get_edge_redirect_link(params['version'], params['arch'])
    redirect redirect_link, 302
  end

  get '/stable' do
    redirect_url = get_stable_redirect_link(params['version'], params['release'])
    redirect redirect_url, 302
  end

  get '/homebrew' do
    unless AVAILABLE_VERSIONS.include?(params['version'])
      halt 412, "Invalid version, please select one of the following versions: #{AVAILABLE_VERSIONS.join(', ')}"
    end

    redirect get_versioned_release_link(params['version'], release_to_filename("#{params['arch']}-binary", params['version'])), 302
  end

  get '/debian/dists/*' do
    page = File.join('dists', params['splat'].first)
    redirect File.join(APT_REPO, page), 302
  end

  get '/fedora/cloudfoundry-cli.repo' do
    redirect File.join(RPM_REPO, 'cloudfoundry-cli.repo'), 302
  end

  get '/fedora/repodata/*' do
    page = File.join('repodata', params['splat'].first)
    redirect File.join(RPM_REPO, page), 302
  end

  get '/debian/pool/*' do
    page = File.join('pool', params['splat'].first)

    filename = page.split('/').last
    version = get_version_from_filename(filename)
    unless version
      version = STABLE_V6_VERSION
      release = filename.split('=').last
      filename = release_to_filename(release, version)
    end
    redirect get_versioned_release_link(version, filename), 302
  end

  get '/fedora/releases/*' do
    page = File.join('releases', params['splat'].first)

    filename = page.split('/').last
    version = get_version_from_filename(filename)
    link = get_versioned_release_link(version, filename)

    redirect format(link, version: version, release: filename), 302
  end

  def page_view(distro, page)
    # Run this async
    @google_analytics.page_view(distro, page)
  end

  def get_version_from_filename(filename)
    match = /.*_(?<version>[\d.]+(-beta\.[\d]+)?)_.*/.match(filename)
    match[:version]
  end

  def get_edge_redirect_link(query_param_version, query_param_arch)
    cli_version = query_param_version || ENV['CURRENT_MAJOR_VERSION']

    unless SUPPORTED_CLI_VERSIONS.include?(cli_version)
      halt 400, "Invalid 'version' query parameter, only #{SUPPORTED_CLI_VERSIONS.join(', ')} or null are allowed"
    end

    unless EDGE_ARCHITECTURES.include?(query_param_arch)
      halt 412, "Invalid 'arch' value, please select one of the following edge: #{EDGE_ARCHITECTURES.join(', ')}"
    end

    version = cli_version.delete('^0-9')
    filename = architecture_to_filename(version, query_param_arch)
    link = get_versioned_edge_link(version, filename)
  end

  def architecture_to_filename(version, architecture)
    suffix = version == '6' ? '' : version

    {
      'linux32' => "cf#{suffix}-cli_edge_linux_i686.tgz",
      'linux64' => "cf#{suffix}-cli_edge_linux_x86-64.tgz",
      'linuxarm64' => "cf#{suffix}-cli_edge_linux_arm64.tgz",
      'macosx64' => "cf#{suffix}-cli_edge_osx.tgz",
      'macosarm' => "cf#{suffix}-cli_edge_macosarm.tgz",
      'windows32' => "cf#{suffix}-cli_edge_win32.zip",
      'windows64' => "cf#{suffix}-cli_edge_winx64.zip"
    }[architecture]
  end

  def get_versioned_edge_link(version, file_name)
    bucket_prefix = version == '6' ? '' : "v#{version}-"

    if ENV['ENVIRONMENT'] == "prod"
      "https://#{bucket_prefix}cf-cli-releases.s3.amazonaws.com/master/#{file_name}"
    else
      "https://cf-cli-dev.s3.amazonaws.com/#{bucket_prefix}cf-cli-releases/master/#{file_name}"
    end
  end

  def get_stable_redirect_link(query_param_version, query_param_release)
    cli_version = query_param_version || ENV['CURRENT_MAJOR_VERSION']

    if cli_version == 'v6'
      cli_version = STABLE_V6_VERSION
    elsif cli_version == 'v7'
      cli_version = STABLE_V7_VERSION
    elsif cli_version == 'v8'
      cli_version = STABLE_V8_VERSION
    end

    validate_stable_link_parameters(query_param_release, cli_version)

    filename = release_to_filename(query_param_release, cli_version)
    get_versioned_release_link(cli_version, filename)
  end

  def validate_stable_link_parameters(release, version)
    unless RELEASE_NAMES.include?(release)
      halt 412, "Invalid 'release' value, please select one of the following releases: #{RELEASE_NAMES.join(', ')}"
    end

    unless AVAILABLE_VERSIONS.include?(version)
      halt 412, "Invalid 'version' value, please select one of the following versions: #{AVAILABLE_VERSIONS.join(', ')}"
    end
  end

  def release_to_filename(release, version)
    major_version = Semantic::Version.new(version).major
    suffix = major_version == 6 ? '' : major_version

    {
      'debian32' => "cf#{suffix}-cli-installer_#{version}_i686.deb",
      'debian64' => "cf#{suffix}-cli-installer_#{version}_x86-64.deb",
      'debianarm64' => "cf#{suffix}-cli-installer_#{version}_arm64.deb",
      'redhat32' => "cf#{suffix}-cli-installer_#{version}_i686.rpm",
      'redhat64' => "cf#{suffix}-cli-installer_#{version}_x86-64.rpm",
      'redhataarch64' => "cf#{suffix}-cli-installer_#{version}_aarch64.rpm",
      'macosx64' => "cf#{suffix}-cli-installer_#{version}_osx.pkg",
      'macosarm' => "cf#{suffix}-cli-installer_#{version}_macosarm.pkg",
      'windows32' => "cf#{suffix}-cli-installer_#{version}_win32.zip",
      'windows64' => "cf#{suffix}-cli-installer_#{version}_winx64.zip",
      'linux32-binary' => "cf#{suffix}-cli_#{version}_linux_i686.tgz",
      'linux64-binary' => "cf#{suffix}-cli_#{version}_linux_x86-64.tgz",
      'linuxarm64-binary' => "cf#{suffix}-cli_#{version}_linux_arm64.tgz",
      'macosx64-binary' => "cf#{suffix}-cli_#{version}_osx.tgz",
      'macosarm-binary' => "cf#{suffix}-cli_#{version}_macosarm.tgz",
      'windows32-exe' => "cf#{suffix}-cli_#{version}_win32.zip",
      'windows64-exe' => "cf#{suffix}-cli_#{version}_winx64.zip"
    }[release]
  end

  def get_versioned_release_link(version, release)
    major_version = Semantic::Version.new(version).major
    bucket_prefix = major_version == 6 ? '' : "v#{major_version}-"

    if ENV['ENVIRONMENT'] == "prod"
      "https://s3-us-west-1.amazonaws.com/#{bucket_prefix}cf-cli-releases/releases/v#{version}/#{release}"
    else
      "https://cf-cli-dev.s3.amazonaws.com/#{bucket_prefix}cf-cli-releases/releases/v#{version}/#{release}"
    end
  end

  run! if app_file == $PROGRAM_NAME
end
