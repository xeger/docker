describe Docker::Session do
  before do
    # squelch spurious output
    subject.shell.interactive = false
  end

  let(:container_id) { subject.run 'busybox', '/bin/sh', interactive:true, tty:true, detach:true }

  describe '#kill' do
    it 'accepts container IDs' do
      subject.kill(container_id)
      # TODO check that container is gone
    end

    it 'accepts container names'
  end

  describe '#rm' do
    it 'accepts container IDs' do
      subject.kill(container_id)
      subject.rm(container_id)
      # TODO check that container is gone
    end

    it 'accepts container names'
  end

  describe '#run' do
    it 'accepts a command and options' do
      output = subject.run('busybox', '/bin/sh', '-c', 'echo "hello world"')
      expect(output).to match(/hello world/)
    end
  end

  describe '#start', slow:true do
    it 'accepts container IDs' do
      subject.stop(container_id, time:1)
      subject.start(container_id)
      # TODO check that container is started
    end
  end

  describe '#stop', slow:true do
    it 'accepts container IDs' do
      subject.stop(container_id, time:1)
      # TODO check that container is stopped
    end
  end

  describe '#version' do
    let(:version) { subject.version }

    it 'returns version information' do
      expect(version).to be_a(Hash)
      expect(version).to have_key('Client Version')
      expect(version).to have_key('Server Version')
    end
  end
end
