describe Colossus::SimpleWriterServer do
  let(:faye_client_double)  { double('faye_client', add_extension: true) }
  let(:faye_double)         { double('faye', add_extension: true, get_client: faye_client_double) }
  let(:faye_extension)      { Colossus::Faye::Extension.new(faye_double, colossus_double) }
  let(:subject)             { Colossus::SimpleWriterServer.new(faye_extension) }
  let(:default_user_ids)    { [ 'user_id', 'user_id_bis' ] }
  let(:writer_token)        { 'WRITER_TOKEN' }
  let(:secret_key)          { 'SECRET_KEY'  }
  let(:token_verifier)      { Colossus::Verifier.new(secret_key, writer_token) }
  let(:colossus_double)     { double('colossus', verifier: token_verifier, set: true, token_verifier: token_verifier) }

  before(:each) do
    Colossus.configure do |conf|
      conf.secret_key   = 'SECRET_KEY'
      conf.writer_token = 'WRITER_TOKEN'
    end
  end

  describe '#presence' do
    let(:default_user_status) { { 'user_id' => 'active', 'user_id_bis' => 'away' } }

    it 'verifies the writer_token' do
      expect { subject.presence('A_WRITER_TOKEN', default_user_ids) }
        .to raise_error('Invalid token')
    end

    it 'verifies the type of user_ids' do
      expect { subject.presence(writer_token, 11) }
        .to raise_error('Invalid user_ids data')
    end

    it 'handles user_ids Array' do
      allow(colossus_double).to receive(:get_multi)
        .with(default_user_ids.first, default_user_ids.last)
        .and_return(default_user_status)
      expect(subject.presence(writer_token, default_user_ids)).to eq(default_user_status)
    end

    it 'handles nil user_ids' do
      allow(colossus_double).to receive(:get_all).and_return(default_user_status)
      expect(subject.presence(writer_token, nil)).to eq(default_user_status)
    end

    it 'handles string user_ids' do
      allow(colossus_double).to receive(:get).and_return('user_id' => 'active')
      expect(subject.presence(writer_token, 'user_id')).to eq('user_id' => 'active')
    end
  end

  describe '#push' do
    let(:message) { 'Hello BMO' }

    it 'verifies the writer_token' do
      expect { subject.push('A_WRITER_TOKEN', default_user_ids, message) }
        .to raise_error('Invalid token')
    end

    it 'verifies the type of user_ids' do
      expect { subject.push(writer_token, 11, message) }
        .to raise_error('Invalid user_ids data')
    end

    it 'does not allow nil user_ids' do
      expect { subject.push(writer_token, nil, message) }
        .to raise_error('Invalid user_ids data')
    end

    it 'handles user_ids Array' do
      allow(faye_client_double).to receive(:publish).with('/users/user_id', message).and_return(true)
      allow(faye_client_double).to receive(:publish).with('/users/user_id_bis', message).and_return(true)
      subject.push(writer_token, default_user_ids, message)
    end

    it 'handles string user_ids' do
      allow(faye_client_double).to receive(:publish).with('/users/user_id', message).and_return(true)
      subject.push(writer_token, 'user_id', message)
    end
  end
end
