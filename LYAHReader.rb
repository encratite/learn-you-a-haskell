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

  def latexifyCode(code)
    replacements =
      [
       ['_', "\\_"],
       ['{', "\\{"],
       ['}', "\\}"],
      ]

    return performReplacements(code, replacements)
  end

  def performReplacements(content, replacements)
    replacements.each do |target, replacement|
      content = content.gsub(target) do |match|
        if replacement.class == Proc
          replacement.call($1)
        else
          replacement
        end
      end
    end
    return content
  end

  def latexLambda(tag)
    lambda { |x| "\\#{tag}{#{x}}" }
  end

  def performMarkupReplacements(content)
    replacements =
      [
       ["\r", ''],

       #broken HTML
       ["elements from an empty list.\n", "elements from an empty list.</p>\n"],
       ["<span class=\"fixed\">True</span>.\n", "<span class=\"fixed\">True</span>.</p>\n"],

       [/ *<h1.*?>(.+?)<\/h1>/, latexLambda('section')],
       [/ *<h2>(.+?)<\/h2>/, latexLambda('subsection')],
       [/<p>(.+?)<\/p>/m, latexLambda('par')],
       [/<a .+?><\/a>\n?/, ''],
       [/<a .+?>(.+?)<\/a>/, latexLambda('textit')],
       [/<i>(.+?)<\/i>/, latexLambda('textit')],
       [/<em>(.+?)<\/em>/, latexLambda('textbf')],
       [/<span class="fixed">(.+?)<\/span>/, lambda { |x| "\\texttt{#{latexifyCode(x)}}" }],
       [/<pre.+?>\n(.+?)<\/pre>/m, latexLambda('lstlisting')],
       [/<(?:div|p) class="hintbox">(.+?)<\/(?:div|p)>/m, latexLambda('lstlisting')],
       [/<span class="label function">(.+?)<\/span>/, latexLambda('texttt')],
       [/<img.+?>\n?/, ''],
       [/ +\n/, "\n"],
       ['&gt;', '>'],
       ['&lt;', '<'],
       ['&amp;', '&'],
      ]

    return performReplacements(content, replacements)
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
    content = performMarkupReplacements(match[1].strip)
    @output += content
  end

  def writeOutput(file)
    File.new(file, 'w+b').write(@output)
  end
end
