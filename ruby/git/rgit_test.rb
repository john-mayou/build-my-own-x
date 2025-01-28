require 'minitest/autorun'
require 'fileutils'
require 'tmpdir'
require 'zlib'

class TestRGitV1 < Minitest::Test

  RGIT_SCRIPT_DIR = File.expand_path('../bin', __FILE__)
  RGIT_ENV_ARGS = 'IS_TEST=true'
  RGIT_LOGS = false

  SHA1_REGEX = /[a-zA-Z0-9]{4}/

  def setup
    @dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.remove_entry @dir
  end

  def rgit_init
    system "#{RGIT_ENV_ARGS} #{RGIT_SCRIPT_DIR}/rgit-init#{log_silencer}"
  end

  def rgit_add(path)
    system "#{RGIT_ENV_ARGS} #{RGIT_SCRIPT_DIR}/rgit-add \"#{path}\"#{log_silencer}"
  end

  def rgit_commit
    system "#{RGIT_ENV_ARGS} #{RGIT_SCRIPT_DIR}/rgit-commit#{log_silencer}"
  end

  def log_silencer
    RGIT_LOGS ? '' : ' > /dev/null'
  end

  def create_rb_file(path, content)
    full_path = "#{@dir}/#{path}"
    FileUtils.mkdir_p File.dirname(full_path)
    File.open(full_path, 'w') { it.write content }
  end

  def find_object(sha:)
    object_path = ".rgit/objects/#{sha[0..1]}/#{sha[2..]}"
    assert File.exist?(object_path)
    File.read(object_path)
  end

  def find_only_sha(blob)
    shas = blob.match(/(#{SHA1_REGEX})/)&.captures
    assert_equal 1, shas.length
    shas.first
  end

  def assert_index_objects
    assert File.exist?('.rgit/index')
    File.readlines('.rgit/index').reduce([]) do |objects, line|
      sha, file_path = line.split(' ')
      blob_path = ".rgit/objects/#{sha[0..1]}/#{sha[2..]}"
      assert File.exist?(blob_path)
      objects << {sha:, file_path:, blob_path:}
    end
  end

  def test_init
    Dir.chdir(@dir) do
      rgit_init

      assert Dir.exist?('.rgit')
      assert Dir.exist?('.rgit/objects')
      assert Dir.exist?('.rgit/objects/info')
      assert Dir.exist?('.rgit/objects/pack')
      assert Dir.exist?('.rgit/refs')
      assert Dir.exist?('.rgit/refs/heads')
      assert Dir.exist?('.rgit/refs/tags')
      assert File.exist?('.rgit/HEAD')
      assert 'ref: refs/heads/master', File.read('.rgit/HEAD')
    end
  end

  def test_add
    Dir.chdir(@dir) do
      rgit_init
      create_rb_file 'path/file.rb', 'puts 1'
      rgit_add 'path/file.rb'
      
      objects = assert_index_objects
      assert_equal 1, objects.length
      assert_equal 'path/file.rb', objects[0][:file_path]
      assert_equal 'puts 1', Zlib::Inflate.inflate(File.read(objects[0][:blob_path]))
    end
  end

  def test_commit
    Dir.chdir(@dir) do
      rgit_init
      create_rb_file 'path/file.rb', 'puts 1'
      rgit_add 'path/file.rb'
      rgit_commit

      assert File.exist?('.rgit/master')
      commit_blob = find_object sha: File.read('.rgit/master')
      root_blob = find_object sha: find_only_sha(commit_blob)
      path_blob = find_object sha: find_only_sha(root_blob)
      file_blob = find_object sha: find_only_sha(path_blob)
      assert_equal 'puts 1', Zlib::Inflate.inflate(file_blob)
    end
  end
end