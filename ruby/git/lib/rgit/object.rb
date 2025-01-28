require 'fileutils'

module RGit

  RGIT_DIR = '.rgit'.freeze

  class Object
    def initialize(sha)
      @sha = sha
    end

    def write(&block)
      object_dir = "#{RGIT_DIR}/objects/#{@sha[0..1]}"
      FileUtils.mkdir_p object_dir
      object_path = "#{object_dir}/#{@sha[2..]}"
      File.open(object_path, 'w', &block)
    end
  end
end