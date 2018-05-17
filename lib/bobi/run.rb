class Run
  def self.cmd(cmd, halt = true)
    LOGGER.info "Exec #{cmd} ...".yellow
    IO.popen("#{cmd} 2>&1") do |io|
      lines = []
      while (line = io.gets) do
        LOGGER.debug line.chomp.blue
        lines << line.chomp
      end
      Process.wait
      exception(lines) if !$?.success? && halt
    end
  end

  def self.exception(lines)
    stack = ['Build error:'] + lines.last(10)
    raise Exception, stack.join("\n")
  end
end
