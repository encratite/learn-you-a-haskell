require_relative 'LYAHReader'

url = 'http://learnyouahaskell.com/chapters'
outputDirectory = 'output'
outputFile = 'Learn You a Haskell for Great Good'
#you probably want to set this to false if you intend to read the PDF on a big screen
useHugeFont = false

reader = LYAHReader.new
#uncomment the following line to perform the download the first time you run this code - I just have it commented out because I always run the stuff from the hard disk right now
#reader.downloadMarkup(url, outputDirectory)
reader.loadChapters(outputDirectory)
reader.writeOutput("#{outputFile}.tex", useHugeFont)
