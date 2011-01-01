# -*- coding: utf-8 -*-
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
       ["\\", "\\textbackslash "],
       #['_', "\\_"],
       ['{', "\\{"],
       ['}', "\\}"],
       ['^', "\\^"],
       #['&', "\\&"],
       #['[', "\\["],
       #[']', "\\]"],
       #['$', "\\$"],
      ]

    return performReplacements(code, replacements)
  end

  def performReplacements(content, replacements)
    replacements.each do |target, replacement|
      content = content.gsub(target) do |match|
        if [Proc, Method].include?(replacement.class)
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

  def latexSingletonLambda(tag)
    lambda { |x| "\\#{tag} #{x}" }
  end

  def latexEnvironmentLambda(tag)
    lambda { |x| "\\begin{#{tag}}\n#{x}\n\\end{#{tag}}" }
  end

  def processSup(x)
    #puts x.inspect
    inner = x.gsub("<sup>", "^{")
    inner = inner.gsub("</sup>", "}")
    #hack
    output = "@@@#{inner}@@@"
    #puts output.inspect
    return output
  end

  def performMarkupReplacements(content)
    replacements =
      [
       ["\r", ''],
       [/(<[a-z]+.+?>)/m, lambda { |x| x.gsub("\n", ' ').gsub('  ', ' ') }],
       [/ *<h1.*?>(.+?)<\/h1>/, latexLambda('section')],
       [/ *<h2>(.+?)<\/h2>/, latexLambda('subsection')],
       [/ *<h3>(.+?)<\/h3>/, latexLambda('subsubsection')],
       [/<p>(.+?)<\/p>/m, latexLambda('par')],
       [/<p>(.*)/, latexLambda('par')],
       [/<a .+?><\/a>\n?/, ''],
       [/<a .+?>(.+?)<\/a>/m, latexLambda('textit')],
       [/<i>(.+?)<\/i>/, latexLambda('textit')],
       [/<em>(.+?)<\/em>/, latexLambda('textbf')],
       [/<b>(.+?)<\/b>/m, latexLambda('textbf')],
       [/<ul>(.+?)<\/ul>/m, latexEnvironmentLambda('itemize')],
       [/ *<li>(.+?)<\/li>/m, latexSingletonLambda('item')],
       [/<span +class="fixed">(.+?)<\/span>/m, lambda { |x| "\\texttt{#{latexifyCode(x)}}" }],
       [/<pre.+?>(.+?)<\/pre>/m, lambda { |x| "\\begin{lstlisting}\n#{latexifyCode(x.strip)}\n\\end{lstlisting}" }],
       [/<(?:div|p) class="hintbox">(.+?)<\/(?:div|p)>/m, latexEnvironmentLambda('lstlisting')],
       [/<span class="(?:label (?:function|type|class|law)|(?:function|class) label)">(.+?)<\/span>/m, lambda { |x| "\\texttt{#{latexifyCode(x)}}" }],
       [/<span style=.+?>(.+?)<\/span>/m, latexLambda('textit')],
       [/<img.+?>\n?/, ''],
       [/\\textit{(.*?<sup>.+?<\/sup>.*?)}/, method(:processSup)],
       [/ +\n/, "\n"],
       ['&gt;', '>'],
       ['&lt;', '<'],
       ['&amp;', "\\&"],
       ['&hellip;', "\\dots"],
       ['&mdash;', "--"],
       ['&ldquo;', "``"],
       ['&rdquo;', "''"],
       ['&nbsp;', ' '],
       ['#', "\\#"],
       ['_', "\\_"],
       ['$', "\\$"],
       ['&&', "\\&\\&"],
       ['%', "\\%"],
       #processSup hack
       ['@@@', '$'],
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

  def getFormattedData
    %q{\documentclass[a4paper,10pt]{article}

\usepackage[english]{babel}

\usepackage[utf8]{inputenc}
\usepackage{tgschola}

\usepackage{listings}

\usepackage{amsmath}
\usepackage{amsfonts}
\usepackage{amssymb}

\usepackage{graphicx}

\usepackage{bbding}

\usepackage{url}

%\setlength{\parindent}{0cm}
\setlength{\parskip}{10pt}

\linespread{1}

%\usepackage{ulem}

%\usepackage[compact]{titlesec}
%\titlespacing{\section}{0pt}{*0}{*0}
%\titlespacing{\section}{0pt}{*0}{*0}
%\titlespacing{\subsection}{0pt}{*0}{*0}

\lstset{numbers=left, frame=single, tabsize=4}

\begin{document}

\title{Learn You A Haskell}
\author{Miran Lipovača}

\maketitle

\tableofcontents
\newpage
} + @output + %q{
\end{document}}
  end

  def writeOutput(file)
    File.new(file, 'w+b').write(getFormattedData)
  end
end
