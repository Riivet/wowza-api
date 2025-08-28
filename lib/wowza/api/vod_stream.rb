class Wowza::Api::VodStream < Wowza::Api::Base
  def self.list
    response = get('/vod_streams')
    if response['vod_streams']
      response['vod_streams'].map{|r| new(r) }
    end
  end

  def self.retrieve(id)
    response = get("/vod_streams/#{id}")
    if response['vod_stream']
      new(response['vod_stream'])
    end
  end

  def destroy
    response = delete("/vod_streams/#{id}")
    return true if response
  end
end