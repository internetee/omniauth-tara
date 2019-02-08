# frozen_string_literal: true

class StrategyTestCase < MiniTest::Test
  class DummyApp
    def call(env); end
  end

  attr_accessor :identifier, :secret, :issuer, :nonce

  def setup
    @identifier = '1234'
    @secret = '1234asdgat3'
    @issuer = 'https://server.example.com'
    @nonce = SecureRandom.hex(16)
  end

  def client
    strategy.client
  end

  def payload
    {
      "iss": issuer,
      "aud": identifier,
      "sub": '248289761001',
      "nonce": nonce,
      "exp": Time.now.to_i + 1000,
      "iat": Time.now.to_i,
    }
  end

  def private_key
    @private_key ||= OpenSSL::PKey::RSA.generate(512)
  end

  def jwt
    @jwt ||= JSON::JWT.new(payload).sign(private_key, :RS256)
  end

  def hmac_secret
    @hmac_secret ||= SecureRandom.hex(16)
  end

  def jwt_with_hs256
    @jwt_with_hs256 ||= JSON::JWT.new(payload).sign(hmac_secret, :HS256)
  end

  def jwt_with_hs512
    @jwt_with_hs512 ||= JSON::JWT.new(payload).sign(hmac_secret, :HS512)
  end

  def jwks
    @jwks ||= begin
      key = JSON::JWK.new(private_key)
      keyset = JSON::JWK::Set.new(key)
      { keys: keyset }
    end
  end

  def user_info
    @user_info ||= OpenIDConnect::ResponseObject::UserInfo.new(
      sub: SecureRandom.hex(16),
      name: Faker::Name.name,
      email: Faker::Internet.email,
      email_verified: Faker::Boolean.boolean,
      given_name: Faker::Name.first_name,
      family_name: Faker::Name.last_name,
      phone_number: Faker::PhoneNumber.phone_number,
    )
  end

  def request
    @request ||= stub('Request').tap do |request|
      request.stubs(:params).returns({})
      request.stubs(:cookies).returns({})
      request.stubs(:env).returns({})
      request.stubs(:scheme).returns({})
      request.stubs(:ssl?).returns(false)
      request.stubs(:path).returns('')
    end
  end

  def id_token_raw_attributes
    { "jti" => "1109a229-feb0-479a-94ee-75640dd6bb0c",
      "iss" => "https://tara-test.ria.ee",
      "aud" => "registreerija",
      "exp" => 1549574273,
      "iat" => 1549545473,
      "nbf" => 1549545173,
      "sub" => "EE10101010005",
      "profile_attributes" => {"date_of_birth" => "1801-01-01",
                               "family_name" => "SMART-ID", "given_name" => "DEMO"},
      "amr" => ["smartid"],
      "state" => "732cfcb126baf71c2fb9",
      "nonce" => "0f8eb2960d02c2f7655f0f9c016ad9ab",
      "at_hash" => "zx8E40ccsJM133gRg5V/3g==" }
  end

  def strategy
    @strategy ||= OmniAuth::Strategies::Tara.new(DummyApp.new).tap do |strategy|
      strategy.options.client_options.identifier = @identifier
      strategy.options.client_options.secret = @secret
      strategy.stubs(:request).returns(request)
      strategy.stubs(:user_info).returns(user_info)
      strategy.stubs(:script_name).returns('')
    end
  end
end
