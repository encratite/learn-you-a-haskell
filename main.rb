require_relative 'LYAHReader'

reader = LYAHReader.new('http://learnyouahaskell.com/chapters')
reader.writeOutput('LearnYouAHaskell.tex')
