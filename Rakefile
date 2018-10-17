# frozen_string_literal: true

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.test_files = FileList['*_test.rb']
  t.warning = false
end

task default: ['test']
