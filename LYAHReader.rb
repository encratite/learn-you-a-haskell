require 'open-uri'
require 'hpricot'
require 'fileutils'

class LYAHReader
  def initialize
    @output = ''
  end

  def download(url)
    puts "Downloading #{url}"
    return open(url).read
  end

  def getChapterName(number)
    return "chapter-#{number}"
  end

  def downloadMarkup(url, outputDirectory)
    markup = download(url)
    index = Hpricot.parse(markup)
    counter = 1
    FileUtils.mkdir_p(outputDirectory)
    index.search('ol') do |content|
      content.search('/li') do |chapter|
        link = chapter.at('/a')
        chapterURL = url.match(/(.+)\/[a-z]+/)[1] + '/' + link['href']
        chapterData = download(chapterURL)
        outputPath = File.join(outputDirectory, getChapterName(counter))
        puts "Writing output to #{outputPath}"
        File.new(outputPath, 'w+b').write(chapterData)
        counter += 1
      end
    end
  end

  def performReplacements(content)
    replacements =
      [
       ["\r", ''],
       [/ *<h1.*?>(.+?)<\/h1>/, "\\section{%s}"],
       [/ *<h2>(.+?)<\/h2>/, "\\subsection{%s}"],
       [/<p>(.+?)<\/p>/m, "\\par{%s}"],
       [/<a .+?><\/a>\n?/, ''],
       [/<a .+?>(.+?)<\/a>/, "\\textit{%s}"],
       [/<img.+?>\n?/, ''],
       [/ +\n/, "\n"],
      ]

    replacements.each do |target, replacement|
      content = content.gsub(target) do
        if $1 == nil
          replacement
        else
          replacement.gsub('%s', $1)
        end
      end
    end
    return content
  end

  def loadChapters(directory)
    counter = 1
    while true
      begin
        path = File.join(directory, getChapterName(counter))
        markup = File.new(path, 'rb').read
        puts "Processing file #{path}"
        processChapter(markup)
      rescue Errno::ENOENT
        break
      end
      counter += 1
    end
  end

  def processChapter(markup)
    pattern = /(<h1.+?>.+?)<div class="footdiv">/m
    match = markup.match(pattern)
    raise 'Unable to extract the content' if match == nil
    content = performReplacements(match[1].strip)
    @output += content
  end

  def writeOutput(file)
    File.new(file, 'w+b').write(@output)
  end
end
