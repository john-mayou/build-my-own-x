require 'digest'

module Blockchain

  GENESIS = ('0' * 64).freeze

  class Block
    attr_reader :data
    attr_reader :prev
    attr_reader :hash
    attr_reader :nonce

    def initialize(data, prev)
      @data         = data
      @prev         = prev
      @nonce, @hash = compute_hash_with_proof_of_work
    end

    def compute_hash_with_proof_of_work(difficulty = '00')
      nonce = 0
      loop do
        hash = Digest::SHA256.hexdigest("#{nonce}#{prev}#{data}")
        if hash.start_with?(difficulty)
          return [nonce, hash]
        else
          nonce += 1
        end
      end
    end
  end
end

b0 = Blockchain::Block.new('data 1', Blockchain::GENESIS)
b1 = Blockchain::Block.new('data 2', b0.hash)
b2 = Blockchain::Block.new('data 3', b1.hash)
b3 = Blockchain::Block.new('data 4', b2.hash)

blockchain = [b0, b1, b2, b3]
pp blockchain