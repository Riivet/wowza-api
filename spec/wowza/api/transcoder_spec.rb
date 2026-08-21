RSpec.describe Wowza::Api::Transcoder do
  let(:transcoder) { described_class.new('id' => 'transcoder-1') }

  describe "#recordings" do
    before do
      allow(transcoder).to receive(:get)
        .with('/transcoders/transcoder-1/recordings')
        .and_return('recordings' => [{ 'id' => 'good' }, { 'id' => 'bad' }])
    end

    it "returns every recording Wowza can retrieve" do
      allow(Wowza::Api::Recording).to receive(:retrieve).with('good').and_return(
        Wowza::Api::Recording.new('id' => 'good')
      )
      allow(Wowza::Api::Recording).to receive(:retrieve).with('bad').and_raise(
        Wowza::Api::Error.new('Recording status is not available!')
      )

      expect(transcoder.recordings.map(&:id)).to eq(['good'])
    end

    it "skips a recording Wowza reports as unavailable instead of raising" do
      allow(Wowza::Api::Recording).to receive(:retrieve).and_raise(
        Wowza::Api::Error.new('Recording status is not available!')
      )

      expect { transcoder.recordings }.not_to raise_error
      expect(transcoder.recordings).to eq([])
    end
  end
end
