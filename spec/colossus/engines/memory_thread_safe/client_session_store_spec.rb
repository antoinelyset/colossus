describe Colossus::Engine::MemoryThreadSafe::ClientSessionStore do
  let(:client_session_store) { described_class.new(4) }

  describe '#sessions' do
    it 'is a ThreadSafe::Cache' do
      expect(client_session_store.sessions).to an_instance_of(ThreadSafe::Cache)
    end

    it 'keeps sessions' do
      client_session_store['session_id'] = 'active'
      client_session_store['session_id_bis'] = 'active'
      expect(client_session_store.sessions.keys.count).to eq(2)
    end
  end

  describe '#status' do
    it 'is disconnected by default' do
      expect(client_session_store.status).to eq('disconnected')
    end

    it 'can be activated' do
      client_session_store['session_id'] = 'active'
      expect(client_session_store.status).to eq('active')
    end

    it 'keeps active between active and disconnected' do
      client_session_store['session_id'] = 'active'
      client_session_store['session_id_bis'] = 'disconnected'
      expect(client_session_store.status).to eq('active')
    end

    it 'keeps active between active and away' do
      client_session_store['session_id'] = 'active'
      client_session_store['session_id_bis'] = 'away'
      expect(client_session_store.status).to eq('active')
    end

    it 'keeps active between active and active' do
      client_session_store['session_id'] = 'active'
      client_session_store['session_id_bis'] = 'active'
      expect(client_session_store.status).to eq('active')
    end

    it 'keeps disconnected between disconnected and disconnected' do
      client_session_store['session_id'] = 'disconnected'
      client_session_store['session_id_bis'] = 'disconnected'
      expect(client_session_store.status).to eq('disconnected')
    end

    it 'keeps away between away and away' do
      client_session_store['session_id'] = 'away'
      client_session_store['session_id_bis'] = 'away'
      expect(client_session_store.status).to eq('away')
    end

    it 'handles disconnection on multiple sessions' do
      client_session_store['session_id'] = 'active'
      client_session_store['session_id'] = 'disconnected'
      expect(client_session_store.status).to eq('disconnected')
    end
  end

  describe '#status_changed?' do
    it 'is true when status is modified' do
      client_session_store['session_id'] = 'active'
      expect(client_session_store.status_changed?).to eq(true)
    end

    it 'is false when the status is modified and still the same' do
      client_session_store['session_id'] = 'active'
      client_session_store['session_id'] = 'active'
      expect(client_session_store.status_changed?).to eq(false)
    end

    it 'is true when the status is modified multiple times' do
      client_session_store['session_id'] = 'active'
      client_session_store['session_id'] = 'disconnected'
      client_session_store['session_id'] = 'active'
      expect(client_session_store.status_changed?).to eq(true)
    end

    it 'is true when the status is modified multiple times by different sessions' do
      client_session_store['session_id'] = 'disconnected'
      client_session_store['session_id_bis'] = 'active'
      expect(client_session_store.status_changed?).to eq(true)
    end

    it 'is false when there is one session active' do
      client_session_store['session_id'] = 'active'
      client_session_store['session_id_bis'] = 'disconnected'
      expect(client_session_store.status_changed?).to eq(false)
    end
  end
end
