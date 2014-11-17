describe 'end to end colossus usage' do
  include TestHelper

  let(:sha)             { OpenSSL::Digest.new('sha1') }
  let(:verifier_secret) { 'please' }
  let(:user_id)         { '1337' }
  let(:token)           { OpenSSL::HMAC.hexdigest(sha, verifier_secret, user_id) }
  let(:extension)       { ClientExtension.new(token) }
  let(:err)             { Proc.new { fail "API request failed" } }
  before(:each)         { ColossusFayeExtension.colossus.reset! }

  it 'should instanciate a server on the colossus path' do
    with_api(GoliathServer) do
      get_request({path: '/colossus/'}, err) do |connection|
        expect(connection.response).to eq("Bad request")
      end
    end
  end

  it 'should instanciate a faye compatible server' do
    with_api(GoliathServer) do
      client = Faye::Client.new('http://localhost:9900/colossus')
      client.add_extension(extension)
      publication = client.publish("/users/#{user_id}", {user_id: user_id, status: 'active'})
      publication.errback do |error|
        fail
      end

      publication.callback do
        expect(true).to eq(true)
        stop
      end
    end
  end

  it 'should handle correctly the user_id' do
    observer = SpecObserver.new do |given_user_id, given_status|
      expect(given_user_id).to eq(user_id)
      stop
    end
    ColossusFayeExtension.colossus.add_observer(observer)
    with_api(GoliathServer) do
      client = Faye::Client.new('http://localhost:9900/colossus')
      client.add_extension(extension)
      publication = client.publish("/users/#{user_id}", {user_id: user_id, status: 'active'})
      publication.errback do |error|
        fail
      end
    end
  end

  it 'should handle correctly the status' do
    observer = SpecObserver.new do |given_user_id, given_status|
      expect(given_status).to eq('active')
      stop
    end
    ColossusFayeExtension.colossus.add_observer(observer)
    with_api(GoliathServer) do
      client = Faye::Client.new('http://localhost:9900/colossus')
      client.add_extension(extension)
      publication = client.publish("/users/#{user_id}", {user_id: user_id, status: 'active'})
      publication.errback do |error|
        fail
      end
    end
  end
end
