require 'digest'

class Block
  attr_reader :data
  attr_reader :hash
  attr_reader :nonce

  def initialize(data)
    @data         = data
    @nonce, @hash = compute_hash_with_proof_of_work
  end

  def compute_hash_with_proof_of_work(difficulty = '00')
    nonce = 0
    loop do
      hash = Digest::SHA256.hexdigest("#{nonce}#{data}")
      if hash.start_with?(difficulty)
        return [nonce, hash]
      else
        nonce += 1
      end
    end
  end
end

pp Block.new('data 1')
pp Block.new('data 2')
pp Block.new('data 3')
pp Block.new('data 4')