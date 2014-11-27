class Colossus
  # Implements the verification logic based on SHA1 in order
  # to avoid timing attacks. (cf Faye doc)
  class Verifier
    attr_reader :sha1, :secret, :writer_token

    def initialize(secret = Colossus.config.secret_key,
                   writer_token = Colossus.config.writer_token)
      @sha1         = OpenSSL::Digest.new('sha1')
      @secret       = secret
      @writer_token = writer_token
    end

    def verify_token(token_given, user_id)
      expected_token = generate_user_token(user_id)
      expected_hash  = Digest::SHA1.hexdigest(expected_token)
      actual_hash    = Digest::SHA1.hexdigest(token_given)
      expected_hash == actual_hash
    end

    def verify_writer_token(token_given)
      expected_hash  = Digest::SHA1.hexdigest(writer_token)
      actual_hash    = Digest::SHA1.hexdigest(token_given)
      expected_hash == actual_hash
    end

    def generate_user_token(user_id)
       OpenSSL::HMAC.hexdigest(sha1, secret, user_id)
    end
  end
end
