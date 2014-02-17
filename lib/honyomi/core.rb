require 'honyomi'
require 'fileutils'

module Honyomi
  class Core
    def initialize(opts = {})
      @opts = opts
    end

    def init_database
      FileUtils.mkdir_p(db_dir)
      Groonga::Database.create(path: db_path)
    end

    private

    def home_dir
      unless @home_dir
        @home_dir = @opts[:home_dir] || File.join(default_home, '.honyomi')
        FileUtils.mkdir_p(@home_dir) unless File.exist?(@home_dir)
      end
      
      @home_dir
    end

    def db_dir
      File.join(home_dir, 'db')
    end

    def db_path
      File.join(db_dir, 'honyomi.db')
    end

    def default_home
      File.expand_path '~'
    end
  end
end
