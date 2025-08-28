class Wowza::Api::OutputList < Wowza::Api::Base
  DEFAULT_OPTIONS = {
    stream_format: 'audiovideo',
  }

  attr_accessor :json

  def initialize(transcoder_id, outputs)
    @transcoder_id = transcoder_id
    begin
      @json = outputs.sort{|a,b| (a['aspect_ratio_height'] || 0) <=> (b['aspect_ratio_height'] || 0)}
    rescue
      @json = outputs
    end
    @outputs = @json.map{|k| Wowza::Api::Output.new(transcoder_id, k)}
  end

  def create(opts={})
    data = {}

    # map options
    if opts[:passthrough]
      opts[:passthrough_audio] = true
      opts[:passthrough_video] = true
    else
      opts[:h264_profile] = opts[:profile] if opts[:profile]
      opts[:aspect_ratio_width] = opts[:width] if opts[:width]
      opts[:aspect_ratio_height] = opts[:height] if opts[:height]
    end

    data = DEFAULT_OPTIONS.merge(opts)

    response = post("/transcoders/#{@transcoder_id}/outputs", output: data)
    if response['output']
      output = Wowza::Api::Output.new(@transcoder_id, response['output'])
      @outputs.push(output)
      return output
    end
  end

  def length
    @outputs.length
  end

  def first
    @outputs.first
  end

  def [](index)
    @outputs[index]
  end

  def find(id)
    @outputs.select{|k| k.id == id }.first
  end

  def last
    @outputs.last
  end

  def each(&block)
    @outputs.each{|o| yield o }
  end

  def map(&block)
    @outputs.map{|o| yield o }
  end

  def select(&block)
    @outputs.select{|o| yield o }
  end

  def find(&block)
    @outputs.find{|o| yield o}
  end
end
