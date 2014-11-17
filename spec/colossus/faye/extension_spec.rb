describe Colossus::Faye::Extension do
  let(:verifier_secret)       { 'A_RANDOM_KEY' }
  let(:verifier_writer_token) { 'A_RANDOM_TOKEN' }
  let(:sha1)                  { OpenSSL::Digest.new('sha1') }
  let(:user_id)               { '1' }
  let(:user_token)            { OpenSSL::HMAC.hexdigest(sha1, verifier_secret, user_id) }
  let(:colossus_spy)          { spy('colossus') }
  let(:token_verifier)        { Colossus::Faye::Verifier.new }

  before(:each) do
    Colossus.configure do |conf|
      conf.verifier_secret = verifier_secret
      conf.verifier_writer_token = verifier_writer_token
    end
  end

  context 'when there is no token' do
    it 'should returns an error' do
      message          =  {}
      expected_message =  {'error' => 'Invalid Token' }
      callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
      subject.incoming(message, nil, callback)
    end

    it 'should removes data field' do
      message          =  {'data' => 'TEST'}
      expected_message =  {'error' => 'Invalid Token' }
      callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
      subject.incoming(message, nil, callback)
    end

    it 'should removes ext field' do
      message          =  {'ext' => 'TEST'}
      expected_message =  {'error' => 'Invalid Token' }
      callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
      subject.incoming(message, nil, callback)
    end

    it 'should removes data ext field' do
      message          =  {'ext' => 'TEST', 'data' => 'TEST'}
      expected_message =  {'error' => 'Invalid Token' }
      callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
      subject.incoming(message, nil, callback)
    end

    it 'should keeps other fields' do
      message          =  {'ext' => 'TEST', 'data' => 'TEST', 'other' => 'TEST'}
      expected_message =  {'error' => 'Invalid Token', 'other' => 'TEST'}
      callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
      subject.incoming(message, nil, callback)
    end
  end

  context 'when there is a user token' do
    context 'when this is an authorized meta channel' do
      it 'returns the channel' do
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => '/meta/handshake'
        }
        expected_message = { 'channel' => '/meta/handshake' }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end
    end

    context 'when this is a subscribe' do
      it 'returns an ok hash for a correct token' do
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => '/meta/subscribe',
          'subscription' => "/users/#{user_id}"
        }
        expected_message = { 'channel' => '/meta/subscribe',
                             'subscription' => "/users/#{user_id}" }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'returns an error for a wrong token' do
        message = {
          'ext'     => { 'user_push_token' => 'A_WRONG_TOKEN' },
          'channel' => '/meta/subscribe',
          'subscription' => "/users/#{user_id}"
        }
        expected_message = { 'channel' => '/meta/subscribe',
                             'subscription' => "/users/#{user_id}",
                             'error' => 'Invalid Token'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'returns an error for a wrong user_id (so a wrong token)' do
        user_id = '2'
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => '/meta/subscribe',
          'subscription' => "/users/#{user_id}"
        }
        expected_message = { 'channel' => '/meta/subscribe',
                             'subscription' => "/users/#{user_id}",
                             'error' => 'Invalid Token'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'returns an error for a glob user_id'  do
        user_id = '*'
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => '/meta/subscribe',
          'subscription' => "/users/#{user_id}"
        }
        expected_message = { 'channel' => '/meta/subscribe',
                             'subscription' => "/users/#{user_id}",
                             'error' => 'The only accepted channel_name is users/:user_id'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'returns an error for an incorrect channel'  do
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => '/meta/subscribe',
          'subscription' => "/admins/#{user_id}"
        }
        expected_message = { 'channel' => '/meta/subscribe',
                             'subscription' => "/admins/#{user_id}",
                             'error' => 'The only accepted channel_name is users/:user_id'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'returns an error for a nested channel'  do
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => '/meta/subscribe',
          'subscription' => "/users/admins/#{user_id}"
        }
        expected_message = { 'channel' => '/meta/subscribe',
                             'subscription' => "/users/admins/#{user_id}",
                             'error' => 'The only accepted channel_name is users/:user_id'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end
    end

    context 'when this is a set status' do
      it 'returns an ok hash for a correct token' do
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => "/users/#{user_id}",
          'data'    => { 'status' => 'active' }
        }
        expected_message = { 'channel' => "/users/#{user_id}" }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'calls colossus for a correct token' do
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => "/users/#{user_id}",
          'data'    => { 'status' => 'active' }
        }
        callback = Proc.new {}
        subject.class.new(colossus_spy, token_verifier).incoming(message, nil, callback)
        expect(colossus_spy).to have_received(:set)
      end

      it 'returns an error for an incorrect status' do
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => "/users/#{user_id}",
          'data'    => { 'status' => 'RANDOM_STATUS' }
        }
        expected_message = {
          'channel' => "/users/#{user_id}",
          'error' => 'Invalid Status'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'returns an error for a wrong token' do
        message = {
          'ext'     => { 'user_push_token' => 'A_WRONG_TOKEN' },
          'channel' => "/users/#{user_id}",
          'data'    => { 'status' => 'active' }
        }
        expected_message = {
          'channel' => "/users/#{user_id}",
          'error' => 'Invalid Token'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'returns an error for a wrong user_id (so a wrong token)' do
        user_id = '2'
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => "/users/#{user_id}",
          'data'    => { 'status' => 'active' }
        }
        expected_message = {
          'channel' => "/users/#{user_id}",
          'error' => 'Invalid Token'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'returns an error for a glob user_id'  do
        user_id = '*'
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => "/users/#{user_id}",
          'data'    => { 'status' => 'active' }
        }
        expected_message = {
          'channel' => "/users/#{user_id}",
          'error' => 'The only accepted channel_name is users/:user_id'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'returns an error for an incorrect channel'  do
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => "/admins/#{user_id}",
          'data'    => { 'status' => 'active' }
        }
        expected_message = {
          'channel' => "/admins/#{user_id}",
          'error' => 'Unknown Action'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'returns an error for a nested channel'  do
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => "/users/admins/#{user_id}",
          'data'    => { 'status' => 'active' }
        }
        expected_message = {
          'channel' => "/users/admins/#{user_id}",
          'error' => 'The only accepted channel_name is users/:user_id'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end
    end
  end
  context 'when there is a server token' do
    context 'when this is a presence request' do
      it 'returns a Hash of statuses in the data' do
        message = {
          'ext'     => { 'writer_token' => verifier_writer_token },
          'channel' => '/presences',
          'data'    => { 'user_ids' => ['1', '2'] }
        }
        expected_message = {
          'channel' => '/presences',
          'data'    => { 'statuses' => { '1' => 'active', '2' => 'active' } }
        }
        colossus_double = double
        allow(colossus_double).to receive(:get_multi).and_return(['active', 'active'])
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.class.new(colossus_double, token_verifier).incoming(message, nil, callback)
      end

      it 'returns a error if the user_ids are not an array' do
        message = {
          'ext'     => { 'writer_token' => verifier_writer_token },
          'channel' => '/presences',
          'data'    => { 'user_ids' => '1' }
        }
        expected_message = {
          'channel' => '/presences',
          'error'   => 'Invalid user_ids data'
        }
        colossus_double = double
        allow(colossus_double).to receive(:get_multi).and_return(['active', 'active'])
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.class.new(colossus_double, token_verifier).incoming(message, nil, callback)
      end

      it 'returns a error if there is no user_ids' do
        message = {
          'ext'     => { 'writer_token' => verifier_writer_token },
          'channel' => '/presences',
          'data'    => { }
        }
        expected_message = {
          'channel' => '/presences',
          'error'   => 'Invalid user_ids data'
        }
        colossus_double = double
        allow(colossus_double).to receive(:get_multi).and_return(['active', 'active'])
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.class.new(colossus_double, token_verifier).incoming(message, nil, callback)
      end
    end

    context 'when this is an authorized meta channel' do
      it 'returns the channel' do
        message = {
          'ext'     => { 'user_push_token' => user_token },
          'channel' => '/meta/handshake'
        }
        expected_message = { 'channel' => '/meta/handshake' }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end
    end

    context 'when this is publish' do
      it 'returns the data' do
        message = {
          'ext'     => { 'writer_token' => verifier_writer_token },
          'channel' => "/users/#{user_id}",
          'data'    => 'lol'
        }
        expected_message = {
          'channel' => "/users/#{user_id}",
          'data'    => 'lol'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'accepts globing' do
        user_id = '*'
        message = {
          'ext'     => { 'writer_token' => verifier_writer_token },
          'channel' => "/users/#{user_id}",
          'data'    => 'lol'
        }
        expected_message = {
          'channel' => "/users/#{user_id}",
          'data'    => 'lol'
        }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end
    end
  end
end
