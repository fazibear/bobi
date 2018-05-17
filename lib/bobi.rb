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

BUILDER = Builder.new()

BUILD_POOL = Concurrent::ThreadPoolExecutor.new(
   min_threads: 1,
   max_threads: 1,
   max_queue: 1000,
)

BUILD_QUEUE = proc do |repo|
  LOGGER.info("Adding #{repo} to queue ...")
  BUILD_POOL.post do
    BUILDER.build(repo)
  rescue => e
    LOGGER.error(e)
  end
end

SLACK_POOL = Concurrent::ThreadPoolExecutor.new(
   min_threads: 1,
   max_threads: 1,
   max_queue: 1000,
)

SLACK_HOOK = ENV['BOBI_SLACK_HOOK']

SLACK_QUEUE = proc do |text, color|
  SLACK_POOL.post do
    if SLACK_HOOK
      payload = {
        username: "bobi",
        icon_emoji: ":bobi:",
        attachments: [
          text: text,
          color: color,
        ]
      }.to_json
      Net::HTTP.post_form(URI.parse(SLACK_HOOK), {'payload' => payload})
    end
  rescue => e
    LOGGER.error(e)
  end
end
