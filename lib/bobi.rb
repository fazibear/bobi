require 'bundler'
Bundler.require(:default)
require 'yaml'
require 'securerandom'
require 'tmpdir'
require 'logger'
require 'json'
require 'net/http'

require_relative 'bobi/run'
require_relative 'bobi/builder'
require_relative 'bobi/web_hook'

LOGGER = Logger.new(ENV['BOBI_LOG'] || STDOUT)
#LOGGER.level = Logger::INFO

POOL = Concurrent::ThreadPoolExecutor.new(
   min_threads: 1,
   max_threads: 1,
   max_queue: 1000,
)

BUILDER = Builder.new()

QUEUE = proc do |repo|
  LOGGER.info("Adding #{repo} to queue ...")
  POOL.post do
    BUILDER.build(repo)
  rescue => e
    LOGGER.error(e)
  end
end
