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
    slack "[#{repo}] Build started!"
    log "Start #{repo} ...".green
    full_repo = "git@github.com:#{repo}.git"
    start_time = Time.now

    tmp = Dir.mktmpdir(PREFIX, @dir)

    log "Cloning #{repo} into #{tmp} ...".green
    Run.cmd("git clone --depth=1 #{full_repo} #{tmp}")

    read_config(tmp).each do |build|
      log "Starting build #{build} ...".green

      uuid = SecureRandom.uuid
      build_dir = "#{tmp}/#{build["path"]}"
      push_to = build["push_to"]

      log "Building from #{build_dir} ...".green
      Run.cmd("docker build -t #{uuid} #{build_dir}")

      Array(push_to).each do |push_repo|
        log "Pushing to #{push_repo} ...".green
        Run.cmd("docker tag #{uuid} #{push_repo}")
        Run.cmd("docker push #{push_repo}")
      end
    rescue Exception => e
      error(e)
    end

    total_time = ChronicDuration.output(Time.now - start_time, :format => :long)

    log "Finished #{repo} in #{total_time}"
    slack "[#{repo}] Build finished in #{total_time}!"
  rescue Exception => e
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

  def slack(txt)
    POOL.post do
      if SLACK_HOOK
        Net::HTTP.post_form(URI.parse(SLACK_HOOK), {'payload' => "{\"text\": \"#{txt}\"}"})
      end
    end
  end
end
