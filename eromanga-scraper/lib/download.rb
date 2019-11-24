# -*- coding: utf-8 -*-
require 'mechanize'
require 'open-uri'
require 'parallel'

module Hentai
  REFERER = 'http://www.google.com/'
  USER_AGENT = 'Mozilla/5.0 (Android; Mobile; rv:21.0) Gecko/21.0 Firefox/21.0'

  class Download
    def initialize(dir)
      @dir = dir
      @agent = Mechanize.new
      @agent.user_agent = USER_AGENT
      @agent.read_timeout = 180
    end

    def download(url_list)
      unless Dir.exist?(@dir) then
        puts "#{@dir}は存在しません"
        return
      end

      url_list.each do |url_info|
        save_dir = get_save_dir(url_info["name"])
        if save_dir.nil?
          puts "保存ディレクトリが作成できませんでした"
          next
        end
        get_url_pages(url_info["url"], save_dir)
      end
    end

    def get_url_pages(url, save_dir)
      case url
      when /e-hentai\.org/
        url_list = get_url_pages_e_hentai(url)
        Parallel.each(url_list, in_threads: 3) do |url_page|
          get_image_link_url(url_page) do |img_url|
            puts img_url
            save_image(save_dir, img_url, {"Referer" => REFERER})
          end
        end
      when /eromanga-mainichi\.com/
        url_list = get_url_pages_eromanga_everyday(url)
        Parallel.each(url_list, in_threads: 3) do |img_url|
          puts img_url
          save_image(save_dir, img_url, {"Referer" => REFERER})
        end
      when /nhentai\.net/
        url_list = get_url_pages_nhentai(url)
        Parallel.each(url_list, in_threads: 3) do |img_url|
          puts img_url
          save_image(save_dir, img_url, {"Referer" => "https://i.nhentai.net/"})
        end
      end
    end

    def get_url_pages_eromanga_everyday(url)
      site = @agent.get(url)
      url_list = []
      lines = (site/ "//div[@id='main']/div/div[1]").search('img')
      lines.each do |line|
        url = line.attribute('src').value
        url_list << url if /img\.eromanga-mainichi\.com/ =~ url
      end

      url_list
    end

    def get_url_pages_e_hentai(url)
      site = @agent.get(url)
      lines = (site/ "//table[@class='ptt']/tr/td/a")
      max_page = 0
      lines.each do |line|
        text = line.inner_html
        max_page = text.to_i if /\d+/ =~ text
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
      lines = (site/ "//div[@class='thumb-container']/a/img")
      lines.each do |line|
        text = line.attribute('data-src').value
        list = text.split('/')
        if /(\d+)t\.(.+)/ =~ list[5]
          url_list << "https://i.nhentai.net/galleries/%s/%s.%s" % [list[4], $~[1], $~[2]]
        end
      end

      url_list
    end

    def get_image_link_url(url)
      get_content_page(url) do |lines|
        lines.each do |line|
          site = @agent.get(line["href"])
          (site/ "//img[@id='img']").each do |real_line|
            yield real_line["src"] if /^https?/ =~ real_line["src"]
          end
        end
      end
    end

    def get_content_page(url)
      site = @agent.get(url)
      lines = (site/ "//div[@class='gdtm']//a")
      if lines.size == 0
        site = @agent.get(url + "?nw=session")
        lines = (site/ "//div[@class='gdtm']//a")
      end

      yield lines
    end

    def save_image(dir, url, options)
      begin
        open(url, options) do |f|
          open(dir + "/" + File.basename(url), 'wb') do |output|
            output.write(f.read)
          end
        end
      rescue => e
        puts e.message
      end
    end

    def get_save_dir(name)
      dir_path = @dir + "/" + name
      unless Dir.exist?(dir_path)
        if Dir.mkdir(dir_path) != 0
          return nil
        end
      end

      dir_path
    end
  end
end
