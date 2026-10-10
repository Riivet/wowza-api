RSpec.describe Wowza::Api::Transcoder do
  subject(:transcoder) { described_class.new('id' => 'abc123') }

  def uptime(id, running: false, started_at: '2026-01-01T00:00:00.000Z')
    { 'id' => id, 'running' => running, 'started_at' => started_at }
  end

  def page(uptimes, page:, total_pages:)
    { 'uptimes' => uptimes, 'pagination' => { 'page' => page, 'total_pages' => total_pages } }
  end

  def stub_pages(*pages)
    pages.each_with_index do |response, i|
      allow(transcoder).to receive(:get)
        .with("/transcoders/abc123/uptimes?page=#{i + 1}").and_return(response)
    end
  end

  describe '#uptimes' do
    it 'returns the uptimes from every page' do
      stub_pages(
        page([uptime('a'), uptime('b')], page: 1, total_pages: 2),
        page([uptime('c')], page: 2, total_pages: 2)
      )

      expect(transcoder.uptimes.map { |u| u['id'] }).to eq(%w[a b c])
    end

    it 'handles a response without pagination' do
      stub_pages({ 'uptimes' => [uptime('a')] })

      expect(transcoder.uptimes.map { |u| u['id'] }).to eq(%w[a])
    end
  end

  describe '#running_uptime' do
    it 'finds the running uptime on a later page' do
      stub_pages(
        page([uptime('old1'), uptime('old2')], page: 1, total_pages: 2),
        page([uptime('old3'), uptime('live', running: true)], page: 2, total_pages: 2)
      )

      expect(transcoder.running_uptime['id']).to eq('live')
    end

    it 'does not fetch earlier pages once the running uptime is found' do
      stub_pages(
        page([uptime('old')], page: 1, total_pages: 3),
        page([uptime('old')], page: 2, total_pages: 3),
        page([uptime('live', running: true)], page: 3, total_pages: 3)
      )

      transcoder.running_uptime

      expect(transcoder).not_to have_received(:get).with('/transcoders/abc123/uptimes?page=2')
    end

    it 'searches back to earlier pages' do
      stub_pages(
        page([uptime('live', running: true)], page: 1, total_pages: 2),
        page([uptime('new')], page: 2, total_pages: 2)
      )

      expect(transcoder.running_uptime['id']).to eq('live')
    end

    it 'picks the most recently started when several are flagged running' do
      stub_pages(
        page([
          uptime('stale', running: true, started_at: '2026-01-01T00:00:00.000Z'),
          uptime('live', running: true, started_at: '2026-02-01T00:00:00.000Z'),
        ], page: 1, total_pages: 1)
      )

      expect(transcoder.running_uptime['id']).to eq('live')
    end

    it 'returns nil when nothing is running' do
      stub_pages(
        page([uptime('a')], page: 1, total_pages: 2),
        page([uptime('b')], page: 2, total_pages: 2)
      )

      expect(transcoder.running_uptime).to be_nil
    end
  end

  describe '#output_target_status' do
    it 'reads target status from the running uptime on a later page' do
      stub_pages(
        page([uptime('old')], page: 1, total_pages: 2),
        page([uptime('live', running: true)], page: 2, total_pages: 2)
      )
      allow(transcoder).to receive(:get).with('/transcoders/abc123/uptimes/live/metrics/current').and_return(
        'current' => {
          'stream_target_status_out1_tgt1' => { 'value' => 'Active' },
          'bytes_in_rate' => { 'value' => 1 },
        }
      )

      expect(transcoder.output_target_status).to eq('tgt1' => { 'out1' => 'Active' })
    end

    it 'returns an empty hash when nothing is running' do
      stub_pages(page([uptime('old')], page: 1, total_pages: 1))

      expect(transcoder.output_target_status).to eq({})
    end
  end
end
