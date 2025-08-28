class Wowza::Api::StreamTarget::Facebook < Wowza::Api::StreamTarget::Base
  def self.list
    response = get('/stream_targets')
    if response['stream_targets']
      response['stream_targets'].
      select{|k| k['type'] == 'facebook'}.
      map{|r| new(r) }
    end
  end

  def self.retrieve(id)
    response = get("/stream_targets/facebook/#{id}")
    if response['stream_target_facebook']
      new(response['stream_target_facebook'])
    end
  end

  def update(data={})
    response = put("/stream_targets/facebook/#{id}", stream_target_facebook: data)
    puts response
    if response['stream_target_facebook']
      @data = response['stream_target_facebook']
    end
  end

  def destroy
    response = delete("/stream_targets/facebook/#{id}")
    return true if response
    return response
  end
end
