describe Colossus::Faye::Extension do
  let(:secret_key)         { 'A_RANDOM_KEY' }
  let(:writer_token)       { 'A_RANDOM_TOKEN' }
  let(:sha1)               { OpenSSL::Digest.new('sha1') }
  let(:user_id)            { '1' }
  let(:user_token)         { OpenSSL::HMAC.hexdigest(sha1, secret_key, user_id) }
  let(:token_verifier)     { Colossus::Verifier.new }
  let(:colossus_double)    { double('colossus', verifier: token_verifier, set: true) }
  let(:faye_client_double) { double('faye_client', publish: true, add_extension: true) }
  let(:faye_double)        { double('faye', add_extension: true, get_client: faye_client_double) }
  let(:subject)            { Colossus::Faye::Extension.new(faye_double, colossus_double) }

  before(:each) do
    Colossus.configure do |conf|
      conf.secret_key = secret_key
      conf.writer_token = writer_token
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
          'ext'     => { 'user_token' => user_token },
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
          'ext'     => { 'user_token' => user_token },
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
          'ext'     => { 'user_token' => 'A_WRONG_TOKEN' },
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
          'ext'     => { 'user_token' => user_token },
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
          'ext'     => { 'user_token' => user_token },
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
          'ext'     => { 'user_token' => user_token },
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
          'ext'     => { 'user_token' => user_token },
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
          'ext'     => { 'user_token' => user_token },
          'channel' => "/users/#{user_id}",
          'data'    => { 'status' => 'active' }
        }
        expected_message = { 'channel' => "/users/#{user_id}" }
        callback = Proc.new { |_message| expect(_message).to eq(expected_message) }
        subject.incoming(message, nil, callback)
      end

      it 'calls colossus for a correct token' do
        message = {
          'ext'     => { 'user_token' => user_token },
          'channel' => "/users/#{user_id}",
          'data'    => { 'status' => 'active' }
        }
        callback = Proc.new {}
        subject.incoming(message, nil, callback)
        expect(colossus_double).to have_received(:set)
      end

      it 'returns an error for an incorrect status' do
        message = {
          'ext'     => { 'user_token' => user_token },
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
          'ext'     => { 'user_token' => 'A_WRONG_TOKEN' },
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
          'ext'     => { 'user_token' => user_token },
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
          'ext'     => { 'user_token' => user_token },
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
          'ext'     => { 'user_token' => user_token },
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
          'ext'     => { 'user_token' => user_token },
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
end
