describe Colossus::Engine::MemoryThreadSafe do
  let(:subject) { described_class.new(4) }

  describe '#gc_ttl' do
    before(:each) do
      allow(Time).to receive(:now) { Time.local('1975', 'may') }
    end

    it 'keeps unexpired session' do
      subject.set('user_id', 'client_id', 'active')

      subject.gc_ttl
      expect(subject.client_sessions.values.length).to eq(1)
    end

    it 'removes expired session' do
      subject.set('user_id', 'client_id', 'active')
      allow(Time).to receive(:now) { Time.local('1975', 'jun') }

      subject.gc_ttl
      expect(subject.client_sessions.values.length).to eq(0)
    end

    it 'removes expired session even on multiple sessions' do
      subject.set('user_id', 'client_id', 'active')
      subject.set('user_id', 'client_id_bis', 'active')
      allow(Time).to receive(:now) { Time.local('1975', 'jun') }

      subject.gc_ttl
      expect(subject.client_sessions.values.length).to eq(0)
    end

    it 'removes expired session even on multiple users' do
      subject.set('user_id', 'client_id', 'active')
      subject.set('user_id_bis', 'client_id', 'active')
      allow(Time).to receive(:now) { Time.local('1975', 'jun') }

      subject.gc_ttl
      expect(subject.client_sessions.values.length).to eq(0)
    end

    it 'removes expired session in sessions stores' do
      subject.set('user_id', 'client_id', 'active')
      allow(Time).to receive(:now) { Time.local('1975', 'jun') }
      subject.set('user_id', 'client_id_bis', 'active')

      subject.gc_ttl
      expect(subject.client_sessions.values.first.sessions.values.length).to eq(1)
    end
  end

  describe '#set' do
    it 'sets the status' do
      subject.set('user_id', 'client_id', 'active')
      expect(subject.client_sessions.values.first.sessions.values.first.status).to eq('active')
    end

    it 'works with get' do
      subject.set('user_id', 'client_id', 'active')
      expect(subject.get('user_id')).to eq('user_id' => 'active')
    end

    it 'deletes the user if the only given status is disconnected' do
      subject.set('user_id', 'client_id', 'active')
      subject.set('user_id', 'client_id', 'disconnected')
      expect(subject.client_sessions.values.length).to eq(0)
    end

    it 'calls user_changed when a user get active' do
      obs = SpecObserver.new do |user_id, status|
        expect([user_id, status]).to eq(['user_id', 'active'])
      end
      subject.add_observer(obs)
      subject.set('user_id', 'client_id', 'active')
    end

    it 'calls user_changed when a user get disconnected' do
      subject.set('user_id', 'client_id', 'active')
      obs = SpecObserver.new do |user_id, status|
        expect([user_id, status]).to eq(['user_id', 'disconnected'])
      end
      subject.set('user_id', 'client_id', 'disconnected')
      subject.add_observer(obs)
    end

    it 'calls user_changed when a user get disconnected' do
      subject.set('user_id', 'client_id', 'active')
      obs = SpecObserver.new do |user_id, status|
        expect([user_id, status]).to eq(['user_id', 'disconnected'])
      end
      subject.set('user_id', 'client_id', 'disconnected')
      subject.add_observer(obs)
    end
  end
end
