class Run
  def self.cmd(cmd, halt = true)
    LOGGER.info "Exec #{cmd} ...".yellow
    IO.popen("#{cmd} 2>&1") do |io|
      while (line = io.gets) do
        LOGGER.debug line.chomp.blue
      end
      Process.wait
      raise Exception if !$?.success? && halt
    end
  end
end
