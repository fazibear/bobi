class Builder
  BUILDS = "builds"
  LOG = "logs"
  PREFIX = "bobi-"
  CONFIG_FILE = ".bobi.yml"
  WORK_DIR = ENV['BOBI_WORKING_DIR'] || "/tmp/bobi"
  SLACK_HOOK = ENV['BOBI_SLACK_HOOK']

  def initialize()
    @dir = WORK_DIR
    FileUtils.mkdir_p(@dir)
  end

  def build(repo)
    slack "*#{repo}* Build started!", '#0000ff'
    log "Start #{repo} ...".green
    full_repo = "git@github.com:#{repo}.git"
    start_time = Time.now

    tmp = Dir.mktmpdir(PREFIX, @dir)

    log "Cloning #{repo} into #{tmp} ...".green
    Run.cmd("git clone --depth=1 #{full_repo} #{tmp}")

    config = read_config(tmp)

    log "Config for #{repo}: #{config}".magenta

    config.each do |build|
      log "Starting build #{build} ...".green

      uuid = "build-#{SecureRandom.uuid}"
      build_dir = "#{tmp}/#{build["path"]}"

      log "Building from #{build_dir} ...".green

      # Run.cmd("docker build -t #{uuid} --cache-from #{uuid} #{build_dir}")
      Run.cmd("docker build -t #{uuid} #{build_dir}")

      Array(build["push_to"]).each do |push_repo|
        log "Pushing to #{push_repo} ...".green
        Run.cmd("docker tag #{uuid} #{push_repo}")
        Run.cmd("docker push #{push_repo}")
        slack "*#{repo}* #{push_repo} pushed!", '#ffff00'
      end

      Run.cmd("docker rmi #{uuid}")

      Array(build["trigger"]).each do |trigger|
        QUEUE.(trigger)
      end
    rescue Exception => e
      slack "*#{repo}* Build error: #{e}!", '#ff0000'
      error(e)
    end

    total_time = ChronicDuration.output(Time.now - start_time, :format => :long)

    log "Finished #{repo} in #{total_time}"
    slack "*#{repo}* Build finished in #{total_time}!", '#36a64f'
  rescue Exception => e
    slack "*#{repo}* Build error: #{e}!", '#ff0000'
    error(e)
  ensure
    FileUtils.remove_entry(tmp) if Dir.exist?(tmp)
  end

  def read_config(dir)
    if File.exist?(config_path(dir))
      config = YAML.load_file(config_path(dir))
      return config if config.is_a?(Array)
      return [config] if config.is_a?(Hash)
      []
    else
      []
    end
  end

  def config_path(dir)
    "#{dir}/#{CONFIG_FILE}"
  end

  def log(line)
    LOGGER.info(line)
  end

  def error(e)
    LOGGER.error(e.to_s.red)
  end

  def slack(text, color = '#000000')
    Thread.new do
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
    end
  end
end
