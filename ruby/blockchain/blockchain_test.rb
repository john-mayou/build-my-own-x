require 'minitest/autorun'
require 'minitest/benchmark'
require_relative 'blockchain'

class TestBlockchain < Minitest::Test

  def sha256(data)
    Digest::SHA256.hexdigest(data)
  end

  def test_hash_calculation
    b0 = Blockchain::Block.new('data 1', Blockchain::GENESIS)
    b1 = Blockchain::Block.new('data 2', b0.hash)
    assert_equal sha256("#{b0.nonce}#{b0.time}#{b0.difficulty}#{b0.prev}#{b0.data}"), b0.hash
    assert_equal sha256("#{b1.nonce}#{b1.time}#{b1.difficulty}#{b1.prev}#{b1.data}"), b1.hash
  end

  def test_proof_of_work_difficulty
    b0 = Blockchain::Block.new('data 1', Blockchain::GENESIS, difficulty: '000')
    b1 = Blockchain::Block.new('data 2', b0.hash, difficulty: '000')
    assert b0.hash.start_with?('000')
    assert b1.hash.start_with?('000')
  end

  def test_prev_hash
    b0 = Blockchain::Block.new('data 1', Blockchain::GENESIS)
    b1 = Blockchain::Block.new('data 2', b0.hash)
    b2 = Blockchain::Block.new('data 2', b1.hash)
    assert_equal b0.prev, Blockchain::GENESIS
    assert_equal b1.prev, b0.hash
    assert_equal b2.prev, b1.hash
  end

  def test_time_moves_forward
    b0 = Time.stub(:now, Time.now - 3) { Blockchain::Block.new('data 1', Blockchain::GENESIS) }
    b1 = Time.stub(:now, Time.now - 2) { Blockchain::Block.new('data 2', b0.hash) }
    b2 = Time.stub(:now, Time.now - 1) { Blockchain::Block.new('data 3', b1.hash) }
    assert b1.time > b0.time
    assert b2.time > b1.time
    assert Time.now.to_i > b2.time
  end
end

if ENV['RUN_BENCH'] == 'true'
  class BenchBlockchain < Minitest::Benchmark
    def bench_proof_of_work
      b0 = Blockchain::Block.new('data 1', Blockchain::GENESIS, difficulty: '00')
      1.upto(5) do |factor|
        difficulty = '0' * factor
        t_start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        block = Blockchain::Block.new('data 2', b0.hash, difficulty: difficulty)
        delta = Process.clock_gettime(Process::CLOCK_MONOTONIC) - t_start
        hashrate = block.nonce / delta
        puts "Hash Rate (#{difficulty}): #{hashrate.to_i}/s"
      end
    end
  end
end