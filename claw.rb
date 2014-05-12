require 'sinatra'

EDGE = {
  'linux32' => 'http://go-cli.s3.amazonaws.com/master/cf-linux-386.tgz',
  'linux64' => 'http://go-cli.s3.amazonaws.com/master/cf-linux-amd64.tgz',
  'macosx64' => 'http://go-cli.s3.amazonaws.com/master/cf-darwin-amd64.tgz',
  'windows32' => 'http://go-cli.s3.amazonaws.com/master/cf-windows-amd32.zip',
  'windows64' => 'http://go-cli.s3.amazonaws.com/master/cf-windows-amd64.zip',
}

get '/hi' do
    "Hello World!"
end

get '/edge' do
  if !params.has_key?('arch') || EDGE[params['arch']].nil?
    halt 412, "Invalid 'arch' value, please select one of the following edge: #{EDGE.keys.join(', ')}"
  end
  redirect EDGE[params['arch']], 302
end
