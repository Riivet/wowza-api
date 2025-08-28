class Wowza::Api::Recording < Wowza::Api::Base
  def self.list
    response = get('/recordings')
    if response['recordings']
      response['recordings'].map{|r| new(r) }
    end
  end

  def self.retrieve(id)
    response = get("/recordings/#{id}")
    if response['recording']
      new(response['recording'])
    end
  end

  def destroy
    response = delete("/recordings/#{id}")
    return true if response
  end
end
