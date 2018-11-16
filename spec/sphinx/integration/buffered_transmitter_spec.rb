require 'spec_helper'

describe Sphinx::Integration::BufferedTransmitter do
  let(:client) { ::ThinkingSphinx::Configuration.instance.mysql_client }
  let(:transmitter) { Sphinx::Integration::Transmitter.new(ModelWithRt) }

  let(:buffered_transmitter) { described_class.new(transmitter, buffered_transmitter_options) }
  let(:buffered_transmitter_options) { {buffer_size: buffer_size} }
  let(:buffer_size) { 2 }

  before(:all) { ThinkingSphinx.context.define_indexes }

  shared_examples 'not buffered calling' do
    let(:callings_args) { Array.new(calling_count) { |index| calling_args.call(index) } }

    before { allow(transmitter).to receive(transmitter_method).and_call_original }

    shared_examples 'calling without batches' do
      it do
        callings_args.each do |args|
          expect(transmitter).to_not have_received(transmitter_method).with(*args)
          calling.call(args)
          expect(transmitter).to have_received(transmitter_method).with(*args)
        end
      end
    end

    context 'when records less than buffer size' do
      let(:calling_count) { buffer_size - 1 }
      it_behaves_like 'calling without batches'
    end

    context 'when calling count equal buffer size' do
      let(:calling_count) { buffer_size }
      it_behaves_like 'calling without batches'
    end

    context 'when calling count more than buffer size' do
      let(:calling_count) { buffer_size * 2 + 1 }
      it_behaves_like 'calling without batches'
    end
  end

  shared_examples 'buffered calling' do
    let(:callings_args) { Array.new(calling_count) { |index| calling_args.call(index) } }

    before { allow(transmitter).to receive(transmitter_method).and_call_original }

    context 'when calling count less than buffer size' do
      let(:calling_count) { buffer_size - 1 }

      it do
        callings_args.each do |args|
          expect(calling.call(args)).to be false # sphinx disabled
          expect(transmitter).to_not have_received(transmitter_method)
        end
      end
    end

    context 'when calling count equal buffer size' do
      let(:calling_count) { buffer_size }

      it do
        callings_args.each do |args|
          expect(calling.call(args)).to be false # sphinx disabled
          expect(transmitter).to_not have_received(transmitter_method)
        end
      end
    end

    context 'when calling count more than buffer size' do
      let(:calling_count) { buffer_size * 2 + 1 }

      it 'call transmitter method with batch equals to buffer_size option' do
        callings_args.each.with_index do |args, index|
          expectation_batch =
            if index.zero?
              []
            else
              callings_args[
                index.pred / buffer_size * buffer_size,
                index.pred % buffer_size + 1
              ]
            end

          have_received_batch =
            have_received(transmitter_method).
              with(*transmitter_first_args + [expectation_batch.flatten] + transmitter_last_args)

          expect(transmitter).to_not have_received_batch
          expect(calling.call(args)).to be false # sphinx disabled

          if expectation_batch.size == buffer_size
            expect(transmitter).to have_received_batch
          else
            expect(transmitter).to_not have_received_batch
          end
        end
      end
    end
  end

  describe '#replace' do
    let(:calling) { ->(args) { buffered_transmitter.replace(*args) } }
    let(:calling_args) { ->(index) { [mock_model(ModelWithRt, id: index)] } }

    context 'when asynchronous option is true' do
      let(:buffered_transmitter_options) { {buffer_size: buffer_size, asynchronous: true} }

      it_behaves_like 'buffered calling' do
        let(:transmitter_method) { :enqueue_action }
        let(:transmitter_first_args) { [:replace] }
        let(:transmitter_last_args) { [] }
      end
    end

    context 'when asynchronous option is false (by default)' do
      it_behaves_like 'buffered calling' do
        let(:transmitter_method) { :replace }
        let(:transmitter_first_args) { [] }
        let(:transmitter_last_args) { [] }
      end
    end
  end

  describe '#delete' do
    let(:calling) { ->(args) { buffered_transmitter.delete(*args) } }
    let(:calling_args) { ->(index) { [mock_model(ModelWithRt, id: index)] } }

    context 'when asynchronous option is true' do
      let(:buffered_transmitter_options) { {buffer_size: buffer_size, asynchronous: true} }

      it_behaves_like 'buffered calling' do
        let(:transmitter_method) { :enqueue_action }
        let(:transmitter_first_args) { [:delete] }
        let(:transmitter_last_args) { [] }
      end
    end

    context 'when asynchronous option is false (by default)' do
      it_behaves_like 'buffered calling' do
        let(:transmitter_method) { :delete }
        let(:transmitter_first_args) { [] }
        let(:transmitter_last_args) { [] }
      end
    end
  end

  describe '#update' do
    let(:calling) { ->(args) { buffered_transmitter.update(*args) } }

    let(:calling_args) do
      ->(index) { [mock_model(ModelWithRt, id: index), {"key_#{index}" => "value_#{index}"}] }
    end

    let(:transmitter_method) { :update }

    context 'when asynchronous option is false (by default)' do
      it_behaves_like 'not buffered calling'
    end

    context 'when asynchronous option is true' do
      let(:buffered_transmitter_options) { {buffer_size: buffer_size, asynchronous: true} }
      it_behaves_like 'not buffered calling'
    end
  end

  describe '#update_fields' do
    let(:calling) { ->(args) { buffered_transmitter.update_fields(*args) } }
    let(:calling_args) { ->(index) { [{"key_#{index}" => "value_#{index}"}] } }
    let(:transmitter_method) { :update_fields }

    context 'when asynchronous option is false (by default)' do
      it_behaves_like 'not buffered calling'
    end

    context 'when asynchronous option is true' do
      let(:buffered_transmitter_options) { {buffer_size: buffer_size, asynchronous: true} }
      it_behaves_like 'not buffered calling'
    end
  end

  describe '#process_immediate' do
    before do
      allow(transmitter).to receive(:replace).and_call_original
      allow(transmitter).to receive(:delete).and_call_original
    end

    context 'when buffered actions not exists' do
      it 'do not anything actions' do
        buffered_transmitter.process_immediate
        expect(transmitter).to_not have_received(:replace)
        expect(transmitter).to_not have_received(:delete)
      end
    end

    context 'when buffered actions exists' do
      let(:replace_args) { Array.new(buffer_size) { |index| [mock_model(ModelWithRt, id: index)] } }
      let(:delete_args) { Array.new(buffer_size) { |index| [mock_model(ModelWithRt, id: index)] } }

      it 'do all buffered actions immediate' do
        replace_args.each { |args| buffered_transmitter.replace(*args) }
        delete_args.each { |args| buffered_transmitter.delete(*args) }

        expect(transmitter).to_not have_received(:replace)
        expect(transmitter).to_not have_received(:delete)
        buffered_transmitter.process_immediate
        expect(transmitter).to have_received(:replace).with(replace_args.flatten)
        expect(transmitter).to have_received(:delete).with(delete_args.flatten)
      end
    end
  end
end
