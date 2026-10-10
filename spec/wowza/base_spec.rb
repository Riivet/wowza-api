RSpec.describe Wowza::Api::Base do
  describe '.request' do
    it 'keeps the query string on GET requests' do
      response = instance_double(Net::HTTPOK, code: '200', body: '{"uptimes":[]}')
      http = instance_double(Net::HTTP)
      allow(Net::HTTP).to receive(:start).and_yield(http)
      allow(http).to receive(:request).and_return(response)

      described_class.get('/transcoders/abc123/uptimes?page=2')

      expect(http).to have_received(:request) do |request|
        expect(request.path).to eq('/api/v1.10/transcoders/abc123/uptimes?page=2')
      end
    end
  end
end
