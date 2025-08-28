class Wowza::Api::StreamTargetList < Wowza::Api::Base
  attr_reader :transcoder_id, :output_id

  def initialize(transcoder_id, output_id)
    @transcoder_id = transcoder_id
    @output_id = output_id
    response = get("/transcoders/#{transcoder_id}/outputs/#{output_id}/output_stream_targets")
    @targets = response.dig('output_stream_targets').map{|t| get_target(t['stream_target']) }
  end

  def add(stream_target_id)
    url = "/transcoders/#{transcoder_id}/outputs/#{output_id}/output_stream_targets"
    data = { stream_target_id: stream_target_id }
    response = post(url, output_stream_target: data)
    if response['output_stream_target']
      target = get_target(response['output_stream_target']['stream_target'])
      @targets << target
      return target
    end
  end

  def remove(stream_target_id)
    url = "/transcoders/#{transcoder_id}/outputs/#{output_id}/output_stream_targets/#{stream_target_id}"
    response = delete(url)
    if response
      @targets.select!{|k| k.id != stream_target_id}
    else
      return false
    end
  end

  def enable(stream_target_id)
    url = "/transcoders/#{transcoder_id}/outputs/#{output_id}/output_stream_targets/#{stream_target_id}/enable"
    response = put(url)
    response.dig('stream_target', 'state')
  end

  def disable(stream_target_id)
    url = "/transcoders/#{transcoder_id}/outputs/#{output_id}/output_stream_targets/#{stream_target_id}/disable"
    response = put(url)
    response.dig('stream_target', 'state')
  end

  def length
    @targets.length
  end

  def first
    @targets.first
  end

  def last
    @targets.last
  end

  def [](index)
    @targets[index]
  end

  def each(&block)
    @targets.each{|o| yield o }
  end

  def map(&block)
    @targets.map{|o| yield o }
  end

  def select(&block)
    @targets.select{|o| yield o }
  end

  def find(&block)
    @targets.find{|o| yield o}
  end

  private

  def get_target(response)
    case response['type']
    when 'wowza' then
      Wowza::Api::StreamTarget::Akamai.retrieve(response['id'])
    when 'fastly' then
      Wowza::Api::StreamTarget::Fastly.retrieve(response['id'])
    when 'custom' then
      Wowza::Api::StreamTarget::Custom.retrieve(response['id'])
    when 'facebook' then
      Wowza::Api::StreamTarget::Facebook.new(response)
    end
  end
end
