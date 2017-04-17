describe Docker::CLI::Getopt do
  subject { described_class }

  describe '.parameters' do
    context 'when given an list of strings' do
      let(:test_parameters) { %w(docker run hello_world) }

      it 'returns the given parameters as it is' do
        expect(subject.parameters(*test_parameters)).to eq test_parameters
      end
    end

    context 'when one of the given params is an array' do
      let(:test_parameters) { ['docker', 'run', ['hello_world', '-f', 'json']] }

      it 'returns the given parameters, but flattened' do
        expect(subject.parameters(*test_parameters)).to eq %w(docker run hello_world -f json)
      end
    end

    context 'when one of the given params is an array' do
      let(:test_options) { { rm: true } }
      let(:test_parameters) { ['docker', 'run', test_options, 'hello_world'] }

      it 'returns a list of the given parameters, with the expected options/flags parsed in' do
        expect(subject.parameters(*test_parameters)).to eq %w(docker run --rm hello_world)
      end
    end
  end

  describe '.options' do
    context 'when given compact options (i.e. -v, -e)' do
      context 'when given boolean options' do
        let(:test_options) { { P: true, t: false } }

        it 'emits flags for options having a ''true'' value' do
          expect(subject.options(test_options)).to include '-P'
        end

        it 'omits flags for options having a ''false'' value' do
          expect(subject.options(test_options)).not_to include '-t'
        end
      end

      context 'when given an array/list option' do
        let :test_options do
          { v: ['/some/path:/path_on_container', '/var/run/docker.sock:/var/run/docker.sock'] }
        end

        it 'emits a list of alternating flag & value for each option item' do
          expect(subject.options(test_options)).to eq [
            '-v',
            '/some/path:/path_on_container',
            '-v',
            '/var/run/docker.sock:/var/run/docker.sock'
          ]
        end
      end

      context 'when given a string-ish object option' do
        let(:test_options) { { u: 'vovimayhem' } }

        it 'emits a list of alternating flag & value for the option' do
          expect(subject.options(test_options)).to eq %w(-u vovimayhem)
        end
      end
    end

    context 'when given long options (i.e. --volume, --env)' do
      context 'when given boolean options' do
        let(:test_options) { { rm: true, tty: false } }

        it 'emits flags for options having a ''true'' value' do
          expect(subject.options(test_options)).to include '--rm'
        end

        it 'omits flags for options having a ''false'' value' do
          expect(subject.options(test_options)).not_to include '--tty'
        end
      end

      context 'when given an array/list option' do
        let :test_options do
          { volume: ['/some/path:/path_on_container', '/var/run/docker.sock:/var/run/docker.sock'] }
        end

        it 'emits a list of ''--flag=value'' for each option item' do
          expect(subject.options(test_options)).to eq [
            '--volume=/some/path:/path_on_container',
            '--volume=/var/run/docker.sock:/var/run/docker.sock'
          ]
        end
      end

      context 'when given a string-ish object option' do
        let(:test_options) { { user: 'vovimayhem' } }

        it 'emits a ''--flag=value'' for the option' do
          expect(subject.options(test_options)).to eq ['--user=vovimayhem']
        end
      end
    end
  end
end
