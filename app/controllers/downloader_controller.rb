class DownloaderController < ApplicationController
  include ActionController::Live
  skip_before_action :verify_authenticity_token
  def index
    render 'index'
  end

  def add_download
    url = Addressable::URI.encode(params[:url])
    @name = File.basename(URI.parse(url).path)
    response_headers = Typhoeus.head(url, followlocation: true)
    download_file = DownloadFile.create!(name: @name, url: url)
    render 'add_download'
    @content_length = response_headers.headers['content-length']
    @content_type = response_headers.headers['content-type']
    if @name.blank?
      content_disposition = response_headers.headers['content-disposition']
      @name = content_disposition.split(',')[-1]&.strip
      @name = @name.gsub('filename=', '')
    end
    @timeline = 'I__________________________________________________I'
    segments = params[:segments_size].to_i
    @timeline_hash = {}
    segment_length = @content_length.to_i / segments
    requests = segments.times.map do |segment|
      downloaded_file = File.open "tmp/temp#{segment}", 'wb'
      byte_start = segment * segment_length
      byte_end = if segment != (segments - 1)
                   (segment + 1) * segment_length - 1
                 else
                   @content_length.to_i
                 end

      @timeline_hash[segment] = { download_distribution: { start_chunk: byte_start, end_chunk: byte_start },
                                  chunk_distribution: { start_chunk: byte_start, end_chunk: byte_end } }

      request = Typhoeus::Request.new(url,
                                      headers: { "Range": "bytes=#{byte_start}-#{byte_end}" })

      request.on_body do |chunk|
        @timeline_hash[segment][:download_distribution][:end_chunk] += chunk.size
        ActionCable.server.broadcast('notes', timeline)
        downloaded_file.write(chunk)
      end

      request.on_complete do |response|
        if response.success?
          downloaded_file.close
        else
          sleep(10)
          request.run
        end
      end

      Thread.new { request.run }
    end

    requests.each(&:join)

    ActionCable.server.broadcast('notes', timeline)
    ActionCable.server.broadcast('notes', 'Done')
    if File.exist?("tmp/#{@name}")
      File.delete("tmp/#{@name}")
      downloaded_file = File.open "tmp/#{@name}", 'wb'
    else
      downloaded_file = File.open "tmp/#{@name}", 'wb'
    end
    segments.times do |segment|
      path_to_file = "tmp/temp#{segment}"
      text = File.open(path_to_file, 'rb').read
      downloaded_file.write text
      File.delete(path_to_file)
    end
  end

  private

  def timeline
    length = @timeline.length
    segment_count = @timeline_hash.keys.count
    @timeline_hash.each do |key, value|
      start_key = (key * length / segment_count)
      end_key = (value[:download_distribution][:end_chunk] * length) / @content_length.to_i
      (start_key...end_key).each do |index|
        @timeline[index] = 'I'
      end
    end
    puts @timeline
    @timeline
  end
end
