require 'mechanize'
require 'open-uri'
require 'parallel'
require 'fileutils'

module Hentai
  REFERER = 'http://www.google.com/'.freeze
  USER_AGENT = 'Mozilla/5.0 (Android; Mobile; rv:21.0) Gecko/21.0 Firefox/21.0'.freeze

  class Download
    def initialize(paths)
      @paths = paths
      @agent = Mechanize.new
      @agent.user_agent = USER_AGENT
      @agent.read_timeout = 180
    end

    def download
      @paths.each do |path, urls|
        unless Dir.exist?(path)
          puts "#{path}は存在しません\n"
          puts "#{path}を作成します\n"
          FileUtils.mkdir_p(path)
          exit
        end

        (urls['urls'] || []).each do |url_info|
          save_dir = get_save_dir(url_info['name'], path)
          if save_dir.nil?
            puts '保存ディレクトリが作成できませんでした'
            next
          end
          get_url_pages(url_info['url'], save_dir)
        end
      end
    end

    def get_url_pages(url, save_dir)
      case url
      when /e-hentai\.org/
        url_list = get_url_pages_e_hentai(url)
        Parallel.each(url_list, in_threads: 3) do |url_page|
          get_image_link_url(url_page) do |img_url|
            puts img_url
            save_image(save_dir, img_url, { 'Referer' => REFERER })
          end
        end
      when /eromanga-mainichi\.com/
        url_list = get_url_pages_eromanga_everyday(url)
        Parallel.each(url_list, in_threads: 3) do |img_url|
          puts img_url
          save_image(save_dir, img_url, { 'Referer' => REFERER })
        end
      when /nhentai\.net/
        url_list = get_url_pages_nhentai(url)
        Parallel.each(url_list, in_threads: 3) do |img_url|
          puts img_url
          save_image(save_dir, img_url, { 'Referer' => 'https://i.nhentai.net/' })
        end
      end
    end

    def get_url_pages_eromanga_everyday(url)
      site = @agent.get(url)
      url_list = []
      lines = (site / "//div[@id='main']/div/div[1]").search('img')
      lines.each do |line|
        url = line.attribute('src').value
        url_list << url if /img\.eromanga-mainichi\.com/.match?(url)
      end

      url_list
    end

    def get_url_pages_e_hentai(url)
      site = @agent.get(url)
      lines = (site / "//table[@class='ptt']/tr/td/a")
      max_page = 0
      lines.each do |line|
        text = line.inner_html
        max_page = text.to_i if /\d+/.match?(text)
      end

      url_list = [url]
      max_page.times do |n|
        url_list << "#{url}?p=#{n}"
      end

      url_list
    end

    def get_url_pages_nhentai(url)
      url_list = []
      site = @agent.get(url)
      lines = (site / "//div[@class='thumb-container']/a/img")
      lines.each do |line|
        text = line.attribute('data-src').value
        list = text.split('/')
        if /(\d+)t\.(.+)/ =~ list[5]
          url_list << `https://i.nhentai.net/galleries/%s/%s.%s` % [list[4], $LAST_MATCH_INFO[1], $LAST_MATCH_INFO[2]]
        end
      end

      url_list
    end

    def get_image_link_url(url)
      get_content_page(url) do |lines|
        lines.each do |line|
          site = @agent.get(line['href'])
          (site / "//img[@id='img']").each do |real_line|
            yield real_line['src'] if /^https?/.match?(real_line['src'])
          end
        end
      end
    end

    def get_content_page(url)
      site = @agent.get(url)
      lines = (site / "//div[@class='gdtm']//a")
      if lines.size.zero?
        site = @agent.get(url + '?nw=session')
        lines = (site / "//div[@class='gdtm']//a")
      end

      yield lines
    end

    def save_image(dir, url, options)
      OpenURI.open_uri(url, options) do |f|
        File.open(dir + '/' + File.basename(url), 'wb') do |output|
          output.write(f.read)
        end
      end
    rescue StandardError => e
      puts e.message
    end

    def get_save_dir(name, path)
      dir_path = path + '/' + name
      unless Dir.exist?(dir_path)
        return nil if Dir.mkdir(dir_path) != 0
      end

      dir_path
    end
  end
end
