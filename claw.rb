# frozen_string_literal: true

require 'sinatra'
require 'gabba'
require 'semantic'

if ENV['ENVIRONMENT'] == "prod"
  EDGE_LINK = 'https://cf-cli-releases.s3.amazonaws.com/master/%{file_name}'
  EDGE_LINK_V6 = 'https://cf-cli-releases.s3.amazonaws.com/master/%{file_name}'
  EDGE_LINK_V7 = 'https://v7-cf-cli-releases.s3.amazonaws.com/master/%{file_name}'
else
  EDGE_LINK = 'https://cf-cli-dev.s3.amazonaws.com/cf-cli-releases/master/%{file_name}'
  EDGE_LINK_V6 = 'https://cf-cli-dev.s3.amazonaws.com/cf-cli-releases/master/%{file_name}'
  EDGE_LINK_V7 = 'https://cf-cli-dev.s3.amazonaws.com/v7-cf-cli-releases/master/%{file_name}'
end

EDGE_ARCH_TO_V6_FILENAMES = {
  'linux32' => 'cf-cli_edge_linux_i686.tgz',
  'linux64' => 'cf-cli_edge_linux_x86-64.tgz',
  'macosx64' => 'cf-cli_edge_osx.tgz',
  'windows32' => 'cf-cli_edge_win32.zip',
  'windows64' => 'cf-cli_edge_winx64.zip'
}.freeze

EDGE_ARCH_TO_V7_FILENAMES = {
  'linux32' => 'cf7-cli_edge_linux_i686.tgz',
  'linux64' => 'cf7-cli_edge_linux_x86-64.tgz',
  'macosx64' => 'cf7-cli_edge_osx.tgz',
  'windows32' => 'cf7-cli_edge_win32.zip',
  'windows64' => 'cf7-cli_edge_winx64.zip'
}.freeze

RELEASE_NAMES = %w[
  debian32
  debian64
  redhat32
  redhat64
  macosx64
  windows32
  windows64
  linux32-binary
  linux64-binary
  macosx64-binary
  windows32-exe
  windows64-exe
].freeze

SUPPORTED_CLI_VERSIONS = [
  'v6',
  'v7'
].freeze

AVAILABLE_VERSIONS = ENV['AVAILABLE_VERSIONS'].split(',')
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

if ENV['ENVIRONMENT'] == "prod"
  VERSIONED_V6_RELEASE_LINK = 'https://s3-us-west-1.amazonaws.com/cf-cli-releases/releases/v%{version}/%{release}'
  VERSIONED_V7_RELEASE_LINK = 'https://s3-us-west-1.amazonaws.com/v7-cf-cli-releases/releases/v%{version}/%{release}'
  APT_REPO = 'https://cf-cli-debian-repo.s3.amazonaws.com/'
  RPM_REPO = 'https://cf-cli-rpm-repo.s3.amazonaws.com/'
else
  VERSIONED_V6_RELEASE_LINK = 'https://cf-cli-dev.s3.amazonaws.com/cf-cli-releases/releases/v%{version}/%{release}'
  VERSIONED_V7_RELEASE_LINK = 'https://cf-cli-dev.s3.amazonaws.com/v7-cf-cli-releases/releases/v%{version}/%{release}'
  APT_REPO = 'https://cf-cli-dev.s3.amazonaws.com/cf-cli-debian-repo'
  RPM_REPO = 'https://cf-cli-dev.s3.amazonaws.com/cf-cli-rpm-repo'
end

FILENAME_VERSION_REGEX = /.*_(?<version>[\d.]+(-beta\.[\d]+)?)_.*/

unless ENV.key?('GA_TRACKING_ID') && ENV.key?('GA_DOMAIN')
  puts 'Expected a Google Analytics env vars but they were not set'
  exit 1
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
  before do
    @google_analytics = Gabba::Gabba.new(ENV['GA_TRACKING_ID'], ENV['GA_DOMAIN'], request.user_agent)
    accept_language = request.env['HTTP_ACCEPT_LANGUAGE']
    @google_analytics.utmul = accept_language if accept_language

    @google_analytics.set_custom_var(1, 'ip', request.ip, 3)
    @google_analytics.set_custom_var(2, 'source', params['source'], 3)
    @google_analytics.set_custom_var(3, 'referer', request.referer, 3)
    @google_analytics.set_custom_var(4, 'host', request.host, 3)
  end

  get '/ping' do
    'pong'
  end

  get /\/(debian|fedora)\/cli\.cloudfoundry\.org\.key/ do
    content_type :text
    ENV['GPG_KEY']
  end

  get '/edge' do
    redirect_link = get_edge_redirect_link(params['version'], params['arch'])
    @google_analytics.page_view('edge', "edge/#{params['arch']}")
    redirect redirect_link, 302
  end

  get '/stable' do
    redirect_url = get_stable_redirect_link(params['version'], params['release'])
    @google_analytics.page_view('stable', "stable/#{params['release']}/#{params['version']}")
    redirect redirect_url, 302
  end

  get '/homebrew/cf-*.tgz' do |version|
    @google_analytics.set_custom_var(2, 'source', 'homebrew', 3)

    unless AVAILABLE_VERSIONS.include?(version)
      halt 412, "Invalid version, please select one of the following versions: #{AVAILABLE_VERSIONS.join(', ')}"
    end

    @google_analytics.page_view('stable', "stable/macosx64-binary/#{version}")
    if Semantic::Version.new(version).major == 7
      redirect format(VERSIONED_V7_RELEASE_LINK, version: version, release: release_to_filename('macosx64-binary', version)), 302
    else
      redirect format(VERSIONED_V6_RELEASE_LINK, version: version, release: release_to_filename('macosx64-binary', version)), 302
    end
  end

  get '/homebrew/cf7-*.tgz' do |version|
    @google_analytics.set_custom_var(2, 'source', 'homebrew', 3)

    unless AVAILABLE_VERSIONS.include?(version)
      halt 412, "Invalid version, please select one of the following versions: #{AVAILABLE_VERSIONS.join(', ')}"
    end

    @google_analytics.page_view('stable', "stable/macosx64-binary/#{version}")
    if Semantic::Version.new(version).major == 7
      redirect format(VERSIONED_V7_RELEASE_LINK, version: version, release: release_to_filename('macosx64-binary', version)), 302
    else
      redirect format(VERSIONED_V6_RELEASE_LINK, version: version, release: release_to_filename('macosx64-binary', version)), 302
    end
  end

  get '/debian/dists/*' do
    page = File.join('dists', params['splat'].first)
    @google_analytics.page_view('debian', page)
    redirect File.join(APT_REPO, page), 302
  end

  get '/fedora/cloudfoundry-cli.repo' do
    @google_analytics.page_view('fedora', 'cloudfoundry-cli.repo')
    redirect File.join(RPM_REPO, 'cloudfoundry-cli.repo'), 302
  end

  get '/fedora/repodata/*' do
    page = File.join('repodata', params['splat'].first)
    @google_analytics.page_view('fedora', page)
    redirect File.join(RPM_REPO, page), 302
  end

  get '/debian/pool/*' do
    page = File.join('pool', params['splat'].first)
    @google_analytics.page_view('debian', page)

    filename = page.split('/').last
    version = get_version_from_filename(filename)
    if version
      link = if Semantic::Version.new(version).major == 7
               VERSIONED_V7_RELEASE_LINK
             else
               VERSIONED_V6_RELEASE_LINK
             end

      redirect format(link, version: version, release: filename), 302
    else
      version = STABLE_V6_VERSION
      release = filename.split('=').last
      redirect format(VERSIONED_V6_RELEASE_LINK, version: version, release: release_to_filename(release, version)), 302
    end
  end

  get '/fedora/releases/*' do
    page = File.join('releases', params['splat'].first)
    @google_analytics.page_view('fedora', page)

    filename = page.split('/').last
    version = get_version_from_filename(filename)
    link = if Semantic::Version.new(version).major == 7
             VERSIONED_V7_RELEASE_LINK
           else
             VERSIONED_V6_RELEASE_LINK
           end
    redirect format(link, version: version, release: filename), 302
  end

  def validate_stable_link_parameters(release, version)
    unless RELEASE_NAMES.include?(release)
      halt 412, "Invalid 'release' value, please select one of the following releases: #{RELEASE_NAMES.join(', ')}"
    end

    unless AVAILABLE_VERSIONS.include?(version)
      halt 412, "Invalid 'version' value, please select one of the following versions: #{AVAILABLE_VERSIONS.join(', ')}"
    end
  end

  def get_version_from_filename(filename)
    has_version = FILENAME_VERSION_REGEX.match(filename)
    if has_version
      has_version.captures.first
    else
      nil
    end
  end

  def release_to_filename(release, version)
    major_version = Semantic::Version.new(version).major
    suffix = major_version == 6 ? '' : major_version

    {
      'debian32' => "cf#{suffix}-cli-installer_#{version}_i686.deb",
      'debian64' => "cf#{suffix}-cli-installer_#{version}_x86-64.deb",
      'redhat32' => "cf#{suffix}-cli-installer_#{version}_i686.rpm",
      'redhat64' => "cf#{suffix}-cli-installer_#{version}_x86-64.rpm",
      'macosx64' => "cf#{suffix}-cli-installer_#{version}_osx.pkg",
      'windows32' => "cf#{suffix}-cli-installer_#{version}_win32.zip",
      'windows64' => "cf#{suffix}-cli-installer_#{version}_winx64.zip",
      'linux32-binary' => "cf#{suffix}-cli_#{version}_linux_i686.tgz",
      'linux64-binary' => "cf#{suffix}-cli_#{version}_linux_x86-64.tgz",
      'macosx64-binary' => "cf#{suffix}-cli_#{version}_osx.tgz",
      'windows32-exe' => "cf#{suffix}-cli_#{version}_win32.zip",
      'windows64-exe' => "cf#{suffix}-cli_#{version}_winx64.zip"
    }[release]
  end

  def get_edge_redirect_link(query_param_version, query_param_arch)
    cli_version = query_param_version || ENV['CURRENT_MAJOR_VERSION']

    if cli_version == 'v7'
      if !query_param_arch || EDGE_ARCH_TO_V7_FILENAMES[query_param_arch].nil?
        halt 412, "Invalid 'arch' value, please select one of the following edge: #{EDGE_ARCH_TO_V7_FILENAMES.keys.join(', ')}"
      end

      format(EDGE_LINK_V7, file_name: EDGE_ARCH_TO_V7_FILENAMES[query_param_arch])
    elsif cli_version == 'v6'
      if !query_param_arch || EDGE_ARCH_TO_V6_FILENAMES[query_param_arch].nil?
        halt 412, "Invalid 'arch' value, please select one of the following edge: #{EDGE_ARCH_TO_V6_FILENAMES.keys.join(', ')}"
      end

      format(EDGE_LINK_V6, file_name: EDGE_ARCH_TO_V6_FILENAMES[query_param_arch])
    else
      halt 400, "Invalid 'version' query parameter, only v6, v7 or null are allowed"
    end
  end

  def get_stable_redirect_link(query_param_version, query_param_release)
    cli_version = query_param_version || ENV['CURRENT_MAJOR_VERSION']

    if cli_version == 'v6'
      cli_version = STABLE_V6_VERSION
    elsif cli_version == 'v7'
      cli_version = STABLE_V7_VERSION
    end

    validate_stable_link_parameters(query_param_release, cli_version)

    if Semantic::Version.new(cli_version).major == 7
      url = VERSIONED_V7_RELEASE_LINK
      filename = release_to_filename(query_param_release, cli_version)
    else
      url = VERSIONED_V6_RELEASE_LINK
      filename = release_to_filename(query_param_release, cli_version)
    end

    format(url, version: cli_version, release: filename)
  end

  run! if app_file == $PROGRAM_NAME
end
