describe Docker::Session do
  before do
    # squelch spurious output
    subject.shell.interactive = false
  end

  let(:container_id) { subject.run 'busybox', '/bin/sh', interactive:true, tty:true, detach:true }

  after do
    subject.kill(container_id) rescue nil
  end

  describe '#inspect' do
    it 'provides container information' do
      info = subject.inspect(container_id)
      expect(info.id).to eq(container_id)
      expect(info).to respond_to(:name)
      expect(info).to respond_to(:status)
    end
    context 'given an empty array of containers' do
      let(:container_id) { [] }
      it 'returns an empty array' do
        info = subject.inspect(container_id)
        expect(info).to eq([])
      end
    end
  end

  describe '#kill' do
    it 'kills containers dead' do
      subject.kill(container_id)
      expect(subject.inspect(container_id).status).to eq('exited')
    end
  end

  describe '#ps' do
    it 'lists containers' do
      container_id
      ps = subject.ps
      expect(ps).to be_a(Array)
      ps.each { |e| expect(e).to be_a(Docker::Container) }
    end
  end

  describe '#rm' do
    it 'removes containers' do
      subject.kill(container_id)
      subject.rm(container_id)
      expect {
        subject.inspect(container_id).status}.to raise_error(Docker::Error)
    end
  end

  describe '#run' do
    it 'accepts a command and options' do
      output = subject.run('busybox', '/bin/sh', '-c', 'echo "hello world"')
      expect(output).to match(/hello world/)
    end

    context 'with multiple volumes' do
      it 'accepts multiple volumes as options' do
        output = subject.run('busybox', '/bin/sh', '-c', 'echo "hello world"', {
          volume: ['/tmp:/foo', '/tmp:/bar']
        })
        expect(output).to match(/hello world/)
      end
    end
  end

  describe '#start' do
    it 'accepts container IDs' do
      subject.stop(container_id, time:0)
      subject.start(container_id)
      expect(subject.inspect(container_id).status).to eq('running')
    end
  end

  describe '#stop' do
    it 'accepts container IDs' do
      subject.stop(container_id, time:0)
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
