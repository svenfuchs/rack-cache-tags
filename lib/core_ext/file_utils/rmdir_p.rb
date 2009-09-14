require 'fileutils'

module FileUtils
  def self.rmdir_p(path)
    begin
      while(true)
        FileUtils.rmdir(path)
        path = File.dirname(path)
      end
    rescue Errno::EEXIST, Errno::ENOTEMPTY, Errno::ENOENT, Errno::EINVAL, Errno::ENOTDIR
      # Stop trying to remove parent directories
    end
  end
end