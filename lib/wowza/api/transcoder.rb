class Wowza::Api::Transcoder < Wowza::Api::Base
  DEFAULT_OPTIONS = {
    billing_mode: 'pay_as_you_go',
    transcoder_type: 'transcoded',
    delivery_method: 'push',
    protocol: 'rtmp',
    recording: true,
    closed_caption_type: 'none',
    disable_authentication: true,
    buffer_size: 8000,
    idle_timeout: 1200,
    stream_smoother: false
  }.freeze

  def self.list
    response = get('/transcoders')
    if response['transcoders']
      response['transcoders'].map{|r| new(r) }
    end
  end

  def self.retrieve(id)
    response = get("/transcoders/#{id}")
    if response['transcoder']
      new(response['transcoder'])
    end
  end

  def reload
    response = get("/transcoders/#{id}")
    if response['transcoder']
      @data = response['transcoder']
    end
  end

  def self.create(opts={})
    data = DEFAULT_OPTIONS.merge(opts)
    response = post('/transcoders', transcoder: data)
    if response['transcoder']
      new(response['transcoder'])
    end
  end

  def update(data={})
    response = put("/transcoders/#{id}", transcoder: data)
    if response['transcoder']
      @data = response['transcoder']
    end
  end

  def destroy
    response = delete("/transcoders/#{id}")
    return true if response
  end

  def rtmp_playback_url
    list = @data.dig('direct_playback_urls', 'rtmp')
    list.find{|k| k['name'] == 'source' }.dig('url')
  end

  def connection_url
    case protocol
    when 'rtmp'
      "rtmp://#{domain_name}:#{source_port}/#{application_name}"
    when 'srt'
      "srt://#{domain_name}:#{source_port}"
    end
  end

  # TODO
  # 1. update/delete output
  # 2. create, remove, destroy stream_target from output

  def properties
    response = get("/transcoders/#{id}/properties")
    ret = Hash.new{ |h,k| h[k] = {} }
    response.dig('properties').each do |item|
      ret[item['section']][item['key']] = item['value']
    end
    return ret
  end

  def property(section, key, value)
    data = {
      section: section,
      key: key,
      value: value
    }
    response = post("/transcoders/#{id}/properties", property: data)
  end

  def remove_property(section, key)
    response = delete("/transcoders/#{id}/properties/#{section}-#{key}")
  end

  def get_property(section, key)
    response = get("/transcoders/#{id}/properties/#{section}-#{key}")
    return response['property']['value'] if response['property']
  end

  def thumbnail
    response = get("/transcoders/#{id}/thumbnail_url")
    return response.dig('transcoder','thumbnail_url') if response.dig('transcoder')
  end

  def state
    response = get("/transcoders/#{id}/state")
    return response.dig('transcoder','state') if response.dig('transcoder')
  end

  def start
    response = put("/transcoders/#{id}/start")
    return response.dig('transcoder','state') if response.dig('transcoder')
  end

  def stop
    response = put("/transcoders/#{id}/stop")
    return response.dig('transcoder','state') if response.dig('transcoder')
  end

  # All uptimes, oldest first. Wowza paginates this list (1000 per page).
  def uptimes
    response = uptimes_page(1)
    ret = response['uptimes'] || []
    (2..total_pages(response)).each do |page|
      ret += uptimes_page(page)['uptimes'] || []
    end
    return ret
  end

  # The uptime currently running, or nil. Uptimes are listed oldest first, so
  # on a long-lived transcoder the running one is on the last page; search
  # from there back.
  def running_uptime
    first = uptimes_page(1)
    total_pages(first).downto(1) do |page|
      response = page == 1 ? first : uptimes_page(page)
      running = (response['uptimes'] || []).select { |k| k['running'] }
      return running.max_by { |k| k['started_at'].to_s } if running.any?
    end
    return nil
  end

  def start_recording
    response = put("/transcoders/#{id}/start_recording")
    return response.dig('transcoder','recording','state') if response.dig('transcoder')
  end

  def stop_recording
    response = put("/transcoders/#{id}/stop_recording")
    return response.dig('transcoder','recording','state') if response.dig('transcoder')
  end

  def recording_state
    response = get("/transcoders/#{id}/recording_state")
    return response.dig('transcoder','recording','state') if response.dig('transcoder')
  end

  def metrics(uptime_id)
    response = get("/transcoders/#{id}/uptimes/#{uptime_id}/metrics/current")
    return response.dig('current')
  end

  def output_target_status
    uptime = running_uptime
    return Hash.new{|h,k| h[k] = {}} unless uptime
    response = metrics(uptime['id'])
    ret = Hash.new{|h,k| h[k] = {} }
    response.each do |k,v|
      if k =~ /stream_target_status/
        _,_,_,output_id,target_id = k.split('_')
        ret[target_id][output_id] = v['value']
      end
    end
    return ret
  end

  def stats
    response = get("/transcoders/#{id}/stats")
    ret = {}
    if response['transcoder']
      response['transcoder'].each do |k,v|
        ret[k] = v.dig('value')
      end
      return ret
    end
  end

  # One transcoder pools recordings across many events, so a single recording that
  # Wowza reports as unavailable (still finalizing, purged, etc) must not blank the rest.
  def recordings
    response = get("/transcoders/#{id}/recordings")
    response['recordings'].filter_map do |r|
      begin
        Wowza::Api::Recording.retrieve(r['id'])
      rescue Wowza::Api::Error => e
        raise unless e.message&.include?('Recording status is not available')
        nil
      end
    end
  end

  def vod_streams
    response = get("/transcoders/#{id}/vod_streams")
    response['vod_streams'].map do |r|
      Wowza::Api::VodStream.retrieve(r['id'])
    end
  end

  # Outputs
  def outputs
    @output_list || Wowza::Api::OutputList.new(id, @data['outputs'])
  end

  def create_output(data)
    response = post("/transcoders/#{id}/outputs", output: data)
    if response['output']
      Wowza::Api::Output.new(id, response['output'])
    end
  end

  def delete_output
  end

  # reset targets
  def reset_target(output_id, stream_target_id)
    response = put("/transcoders/#{id}/outputs/#{output_id}/output_stream_targets/#{stream_target_id}/restart")
    return response
  end

  private

  def uptimes_page(page)
    get("/transcoders/#{id}/uptimes?page=#{page}")
  end

  def total_pages(response)
    [response.dig('pagination', 'total_pages').to_i, 1].max
  end
end
