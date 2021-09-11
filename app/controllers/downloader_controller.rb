class DownloaderController < ApplicationController

  def index
    render 'index'
  end

  def add_download
    url = Addressable::URI.encode(params[:url])
    name = File.basename(URI.parse(url).path)
    response = Typhoeus.head(url, followlocation: true)
    content_length = response.headers['content-length']
    content_type = response.headers["content-type"]
    if name.blank?
      content_disposition = response.headers["content-disposition"]
      name = content_disposition.split(',')[-1]&.strip
      name = name.gsub('filename=', '')
    end
    @timeline = "I__________________________________________________I"
    segments = params[:segment_size].to_i
    @timeline_hash = {}
    segment_length = content_length.to_i / segments
    hydra = Typhoeus::Hydra.new(max_concurrency: 5)
    requests = segments.times.map do |segment|
      downloaded_file = File.open "tmp/temp#{segment}", 'wb'
      byte_start = segment*segment_length
      byte_end = if segment != (segments-1)
                   (segment+1)*segment_length-1
                 else
                   content_length.to_i
                 end

      @timeline_hash[segment] = { download_distribution: {start_chunk: byte_start, end_chunk: byte_start},
                                  chunk_distribution: {start_chunk: byte_start, end_chunk: byte_end} }

      request = Typhoeus::Request.new(url,
                                      headers: { "Range": "bytes=#{byte_start}-#{byte_end}" })
      request.on_body do |chunk|
        # puts chunk
        @timeline_hash[segment][:download_distribution][:end_chunk] += chunk.size
        timeline(content_length)
        downloaded_file.write(chunk)
      end

      request.on_complete do |response|
        if response.success?
          downloaded_file.close
          puts "bytes=#{byte_start}-#{byte_end}"
        else
          puts "bytes=#{byte_start}-#{byte_end}"
          sleep(10)
          request.run
        end
      end

      Thread.new {request.run}
    end

    requests.each(&:join)

    if File.exist?("tmp/#{name}")
      downloaded_file = File.open "tmp/2#{name}", 'wb'
    else
      downloaded_file = File.open "tmp/#{name}", 'wb'
    end
    segments.times do |segment|
      path_to_file = "tmp/temp#{segment}"
      text = File.open(path_to_file, 'rb').read
      p text.size
      downloaded_file.write text
      # File.delete(path_to_file)
    end
    render json: @timeline_hash
  end

  private

  def timeline(content_length)
    length = @timeline.length
    segment_count = @timeline_hash.keys.count
    @timeline_hash.each do |key, value|
      start_key = (key * length / segment_count)
      end_key = (value[:download_distribution][:end_chunk] * length) / content_length.to_i
      (start_key...end_key).each do |index|
        @timeline[index] = 'I'
      end
    end
    puts @timeline
  end
end
