# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Riddle::Client do
  let(:server_pool) { double('Sphinx::Integration::ServerPool') }
  let(:server) { double('Sphinx::Integration::Server') }
  let(:client) { described_class.new(['127.0.0.1', '127.0.0.2'], 10_301) }
  let(:socket) { double('Socket', fd: 1) }

  let(:connection) { double('Sphinx::Integration::Connection') }

  before do
    allow(connection).to receive(:socket).and_return socket
    allow(server).to receive(:take).and_yield connection
    allow(server_pool).to receive(:take).and_yield server
  end

  describe '#new' do
    it 'server_pool should be initizlized' do
      expect(client.class.server_pool).to be_a(::Sphinx::Integration::ServerPool)
    end
  end

  describe '#connect' do
    before { allow(described_class).to receive(:server_pool).and_return server_pool }
    it 'should yield connection socket' do
      expect { |b| client.send(:connect, &b) }.to yield_with_args(socket)
    end
  end

  describe '#request' do
    let(:status) { ::Riddle::Client::Statuses[:retry] }
    let(:version) { 1 }
    let(:length) { 0 }
    let(:header_response) { [status, version, length].pack('n2N') }

    before do
      allow(described_class).to receive(:server_pool).and_return server_pool
      allow(socket).to receive(:send)
    end

    context 'when blocking' do
      context 'when respond with retry status' do
        before { allow(socket).to receive(:recv).with(described_class::HEADER_LENGTH).and_return header_response }

        it 'responds with error' do
          expect(socket).to receive(:recv)
          expect { client.send(:request, :search, 'foo') }.to raise_error(
            ::Riddle::ResponseError,
            /Searchd responded with retry error/
          )
        end
      end

      context 'when respond with ok status' do
        let(:status) { ::Riddle::Client::Statuses[:ok] }
        let(:response) { 'Hello, world!' }
        let(:length) { response.bytesize }

        before do
          allow(socket).to receive(:recv).with(described_class::HEADER_LENGTH).ordered.and_return header_response
          allow(socket).to receive(:recv).with(length).ordered.and_return response
        end

        it 'responds with greeting' do
          expect(socket).to receive(:recv).twice
          expect(client.send(:request, :search, 'foo')).to eq(response)
        end
      end
    end

    context 'when read_nonblock' do
      let!(:cfg_before) { ::Sphinx::Integration[:socket_read_timeout_sec] }
      after { ::Sphinx::Integration[:socket_read_timeout_sec] = cfg_before }
      before do
        ::Sphinx::Integration[:socket_read_timeout_sec] = 1
      end

      context 'when respond with retry status' do
        let(:status) { ::Riddle::Client::Statuses[:retry] }
        before do
          allow(IO).to receive(:select).with([socket], [], [], 1).and_return socket.fd
          allow(socket).to receive(:read_nonblock).with(described_class::HEADER_LENGTH).ordered.and_return(
            header_response
          )
        end

        it 'responds with error' do
          expect(socket).to receive(:read_nonblock).exactly(1).times
          expect(IO).to receive(:select).exactly(1).times # read only header
          expect(socket).not_to receive(:recv)
          expect { client.send(:request, :search, 'foo') }.to raise_error(
            ::Riddle::ResponseError,
            /Searchd responded with retry error/
          )
        end
      end

      context 'when respond with ok status' do
        let(:status) { ::Riddle::Client::Statuses[:ok] }
        let(:response) { 'Hello, world!' }
        let(:length) { response.bytesize }

        context 'when all data in buffer of the socket are present' do
          before do
            allow(IO).to receive(:select).with([socket], [], [], 1).and_return socket.fd
            allow(socket).to receive(:read_nonblock).with(described_class::HEADER_LENGTH).ordered.and_return(
              header_response
            )
            allow(socket).to receive(:read_nonblock).with(length).ordered.and_return response
          end

          it 'responds with greeting' do
            expect(socket).to receive(:read_nonblock).twice
            expect(IO).to receive(:select).twice
            expect(socket).not_to receive(:recv)
            expect(client.send(:request, :search, 'foo')).to eq(response)
          end
        end

        context 'when partial read' do
          before do
            allow(IO).to receive(:select).with([socket], [], [], 1).and_return socket.fd
            allow(socket).to receive(:read_nonblock).with(described_class::HEADER_LENGTH).ordered.and_return(
              header_response
            )

            allow(socket).to receive(:read_nonblock).with(length).ordered.and_return response[0..5]
            allow(socket).to receive(:read_nonblock).with(length - response[0..5].bytesize).ordered
              .and_return response[6..-1]
          end

          it 'responds with greeting' do
            expect(socket).to receive(:read_nonblock).exactly(3).times
            expect(IO).to receive(:select).twice # read header + read body
            expect(socket).not_to receive(:recv)
            expect(client.send(:request, :search, 'foo')).to eq(response)
          end
        end

        context 'when read timeout' do
          before do
            # First call - ok, second - time out
            allow(IO).to receive(:select).with([socket], [], [], 1).and_return socket.fd, nil

            allow(socket).to receive(:read_nonblock).with(described_class::HEADER_LENGTH).and_return(
              header_response
            )
          end

          it 'responds with error' do
            expect(socket).to receive(:read_nonblock).exactly(1).times
            expect(IO).to receive(:select).twice # read header + read body
            expect(socket).not_to receive(:recv)
            expect { client.send(:request, :search, 'foo') }.to raise_error(
              ::Riddle::ResponseError,
              /Timeout reading from socket/
            )
          end
        end

        context 'when read_nonblock raised EAGAIN' do
          # used datagram socket here to emulate working without connection establishment
          let(:socket) { Socket.new(:INET, :DGRAM) }

          before do
            allow(IO).to receive(:select).with([socket], [], [], 1).and_return 1, 1

            allow(socket).to receive(:read_nonblock).with(described_class::HEADER_LENGTH).ordered.and_return(
              header_response
            )
            allow(socket).to receive(:read_nonblock).with(length).ordered.and_call_original
          end

          after { socket.close }

          it 'responds with error' do
            expect(socket).to receive(:read_nonblock).twice
            expect(IO).to receive(:select).twice # read header + read body
            expect(socket).not_to receive(:recv)
            expect { client.send(:request, :search, 'foo') }.to raise_error(
              ::Riddle::ResponseError,
              /Timeout reading from socket/
            )
          end
        end
      end
    end
  end
end
