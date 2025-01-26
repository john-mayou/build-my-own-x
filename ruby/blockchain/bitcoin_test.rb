require 'minitest/autorun'
require_relative 'bitcoin'

class TestBitcoin < Minitest::Test
  [
    {
      hash: {
        version:     1,
        prev:       '0000000000000000000000000000000000000000000000000000000000000000',
        merkleroot: '4a5e1e4baab89f3a32518a88c31bc87f618f76673e2cc77ab2127b7afdeda33b',
        time:        1231006505,
        bits:       '1d00ffff',
        nonce:       2083236893
      },
      expected: '000000000019d6689c085ae165831e934ff763ae46a2a6c172b3f1b60a8ce26f'
    },
    {
      hash: {
        version:     1,
        prev:       '00000000000008a3a41b85b8b29ad444def299fee21793cd8b9e567eab02cd81',
        merkleroot: '2b12fcf1b09288fcaff797d71e950e71ae42b91e8bdb2304758dfcffc2b620e3',
        time:        1305998791,
        bits:       '1a44b9f2',
        nonce:       2504433986
      },
      expected: '00000000000000001e8d6829a8a21adc5d38d0a473b144b6765798e61f98bd1d'
    }
  ].each_with_index do |tt, index|
    define_method("test_bitcoin_#{index}") do
      assert_equal tt[:expected], Bitcoin::Header.from_hash(tt[:hash]).hash
    end
  end
end