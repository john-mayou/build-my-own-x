require 'digest'

module Bitcoin
  class Header
    attr_reader :version
    attr_reader :prev
    attr_reader :merkleroot
    attr_reader :time
    attr_reader :bits
    attr_reader :nonce

    def initialize(version, prev, merkleroot, time, bits, nonce)
      @version    = version
      @prev       = prev
      @merkleroot = merkleroot
      @time       = time
      @bits       = bits
      @nonce      = nonce
    end

    def self.from_hash(h)
      new(
        h[:version],
        h[:prev],
        h[:merkleroot],
        h[:time],
        h[:bits],
        h[:nonce]
      )
    end

    def to_bin
       i4(@version)       +
      h32(@prev)          +
      h32(@merkleroot)    +
       i4(@time)          +
       i4(@bits.to_i(16)) +
       i4(@nonce)
    end

    def hash
      bin_to_h32(sha256(sha256(to_bin)))
    end

    def sha256(bytes)
      Digest::SHA256.digest(bytes)
    end

    def i4(num)
      [num].pack('V')
    end

    def h32(hex)
      [hex].pack('H*').reverse
    end

    def bin_to_h32(bytes)
      bytes.reverse.unpack('H*')[0]
    end
  end
end