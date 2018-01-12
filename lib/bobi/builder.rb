class Builder
  BUILDS = "builds"
  LOG = "logs"
  PREFIX = "bobi-"
  CONFIG_FILE = ".bobi.yml"

  def initialize(dir)
    FileUtils.mkdir_p(dir)
    @dir = dir
    @status = :new
  end

  def build(repo)
    log "Start #{repo} ...".green
    repo = "git@github.com:#{repo}.git"
    start_time = Time.now

    tmp = Dir.mktmpdir(PREFIX, @dir)

    log "Cloning #{repo} into #{tmp} ...".green
    Run.cmd("git clone --depth=1 #{repo} #{tmp}")

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

      total_time = Time.now - start_time

      log "Finished #{repo} in #{total_time}s"
    end
  rescue Exception => e
    LOGGER.error(e)
    @status = :faled
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
end
