# -*- coding: utf-8 -*-
$: << File.dirname(__FILE__) + "/../lib"
require 'download'
require 'optparse'
require 'yaml'

config = {}
OptionParser.new do |opt|
  opt.on('-f', '--file FILE') {|v| config[:file] = v}
  opt.parse!
end

obj = YAML.load_file(config[:file]) if File.exist?(config[:file])
dir = obj["dir"]
url_list = obj["url_list"]

hentai = Hentai::Download.new(dir)
hentai.download(url_list)
