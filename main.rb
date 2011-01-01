require_relative 'LYAHReader'

url = 'http://learnyouahaskell.com/chapters'
outputDirectory = 'output'

reader = LYAHReader.new
#reader.downloadMarkup(url, outputDirectory)
reader.loadChapters(outputDirectory)
reader.writeOutput('LearnYouAHaskell.tex')
