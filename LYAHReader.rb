require 'open-uri'
require 'hpricot'

class LYAHReader
  def initialize(url)
    @output = ''
    load(url)
  end

  def load(url)
    markup = open(url)
    index = Hpricot.parse(markup)
    index.search('ol') do |content|
      content.search('/li') do |chapter|
        link = chapter.at('/a')
        chapterURL = url.match(/(.+)\/[a-z]+/)[1] + '/' + link['href']
        processChapter(chapterURL)
      end
    end
  end

  def performReplacements(content)
    replacements =
      [
       [/<h1.+?>/, "\\section{"],
       ['</h1>', '}'],
       ["<p>\n", "\par{"],
       ["\n</p>", '}'],
      ].each do |target, replacement|
      content = content.gsub(target, replacement)
    end
    return content
  end

  def processChapter(url)
    puts "Processing chapter at URL #{url}"
    markup = open(url).read
    File.new('test', 'w+').write(markup)
    pattern = /(<h1.+?>.+?)<div class="footdiv">/m
    match = markup.match(pattern)
    raise 'Unable to extract the content' if match == nil
    content = performReplacements(match[1])
    @output += content
  end

  def writeOutput(path)
    File.new(path, 'wb+').write(@output)
  end
end
