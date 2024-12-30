analyzer.rb
「require_relative 'categories'
require_relative 'category'

class Analyzer
  def initialize
    @categories = Categories.new
  end
  attr_reader :categories
  
  def train(text, category_name)
    category = @categories.search(category_name)
    category.train(text)
  end

  def classify(text)
    @categories.classify(text)
  end
end」






app.rb
「require_relative 'analyzer'
require_relative 'categories'
require_relative 'category'
require_relative 'doc'
require_relative 'grabber'

class App
  def initialize
    @analyzer = Analyzer.new
    @grabber = Grabber.new
  end
  attr_reader :analyzer, :grabber
  
  def train(text,category)
    analyzer.train(text,category)
  end

  def classify(url_or_file)
    text = grabber.grab(url_or_file)
    puts text
    analyzer.classify(text)
  end
end」






categories_classifyable.rb
「module CategoriesClassifyable
  def classify(text)
    doc = Doc.new(text)
    sorted_categories_by_doc(doc).last
  end

  private

  def sorted_categories_by_doc(doc)
    categories.sort do |a,b|
      compare_categories(doc,a,b)
    end
  end

  def categories
    category_list.values
  end

  def compare_categories(doc,a,b)
    score_a=
      a.score(doc, total_train_count, used_words.count)
    score_b=
      b.score(doc, total_train_count, used_words.count)
    score_a <=> score_b
  end

  def total_train_count
    categories.map(&:num_trained_docs).sum.to_f
  end

  def used_words
    categories.map do |category|
      category.used_words
    end.inject(&:+)
  end
end」






categories_test.rb
「require_relative 'categories'

categories = Categories.new
puts categories.category_list.inspect

categories.search(:spam)
puts categories.category_list.inspect

categories.search(:normal)
puts categories.category_list.inspect」






categories.rb
「require_relative 'category'
require_relative 'categories_classifyable'

class Categories
  def initialize
    @category_list = {}
  end
  attr_reader :category_list
  
  def search(category_name)
    @category_list[category_name] ||= Category.new(category_name)
  end

  include CategoriesClassifyable
end」






category_test.rb
「require_relative 'category'

category = Category.new(:spam)
puts category.documents.inspect

category.train("hello")
puts category.documents.inspect」






category_trainable.rb
「module CategoryTrainable
  def train(text)
    doc = Doc.new(text)
    @documents << doc
    store_words(doc)
  end

  def store_words(doc)
    doc.words.each do |word|
      store_word(word)
    end
  end

  def store_word(word)
    @words[word] ||= 0
    @words[word] += 1
  end
end」






category.rb
「require_relative 'doc'
require_relative 'category_trainable'

class Category
  def initialize(name) 
    @documents = []
    @name = name
    @words = {}
  end
  attr_reader :documents, :name
  
include CategoryTrainable

  def num_trained_docs
    documents.count
  end

  def used_words
    @words.keys
  end

  def score(doc, num_total_docs, num_total_words)
    base_score(num_total_docs) + words_score(doc.words, num_total_words)
  end

  def base_score(num_total_docs)
    Math.log(base_prob(num_total_docs))
  end
  
  def words_score(words, num_total_words)
    words.map do |word|
      Math.log(word_prob(word, num_total_words))
    end.sum
  end
  
def base_prob(num_total_docs)
  documents.count.to_f / num_total_docs.to_f
end

  def word_prob(word, num_total_words)
    (num_word(word) + 1.0) / (num_words + num_total_words * 1.0)
  end

  def num_word(word)
    @words[word] || 0
  end

  def num_words
    @words.keys.size
  end
end」






doc_test.rb
「require_relative 'doc'

doc = Doc.new("hello world")

puts doc.text
puts doc.words.inspect」






doc.rb
「require_relative 'words_selector'
require_relative 'words_splitter'

class Doc
  def initialize(text)
    @text = text
    @@words_selector ||= WordsSelector.new
  end

  attr_reader :text

  def words
    words = WordsSplitter.split(text)
    target_words = WordsSelector.select(words)
    target_words.map do |word|
      word.original
    end
  end
end」






grabber.rb
「require 'open-uri'
require 'nokogiri'

class Grabber
  def grab(uri_or_file)
    if File.exists?(uri_or_file)
      grab_from_file(uri_or_file)
    else
      grab_from_uri(uri_or_file)
    end
    end
  
  def grab_from_uri(uri)
    html = URI.open(uri).read
    remove_tags(html)
  end

  def grab_from_file(file)
    File.open(file).read
  end

  def grab_from_htmlfile(html_file)
    html = File.open(html_file).read
    remove_tags(html)
  end

  private
  def remove_tags(html)
    doc = Nokogiri::HTML.parse(html)
    doc.text
  end
end」






main.rb
「require_relative 'app'

app = App.new

app.train("これはSPAM文章です。", :spam)
app.train("これは通常の文章です。", :normal)


result = app.classify(ARGV[0])

puts result.name」






nokogiri_sample.rb
「require 'open-uri'
require 'nokogiri'

html = URI.open('https://bukkyo-u-programming-course.s3.ap-northeast-1.amazonaws.com/c2-1.html').read

doc = Nokogiri::HTML.parse(html)
puts doc.text」






open_uri_sample.rb
「require 'open-uri'

html = URI.open('https://bukkyo-u-programming-course.s3.ap-northeast-1.amazonaws.com/c2-1.html').read
puts html」






suika_test.rb
「require 'suika'

tagger = Suika::Tagger.new

text = "私は京都で働いたことがあります。"

result = tagger.parse(text)
result.each do |token|
  puts token
end」






word_test.rb
「require_relative 'word'
require 'suika'

tagger = Suika::Tagger.new
lines = tagger.parse('わたしは京都にいます。')

word = Word.new(lines[0])
puts word.is_noun? 
puts word.is_verb?
puts word.word.inspect
puts word.original.inspect
puts word.attributes.inspect
puts word.attribute_list.inspect」






word.rb
「class Word
def initialize(line)
  @line = line
end
  attr_reader :line

  def is_noun?
    attribute_list[0] == '名詞'
  end

  def is_verb?
    attribute_list[0] == '動詞'
  end

  def original
    attribute_list[6]
  end
  
  def word
    line.split(/\t/)[0]
  end

  def attributes
    line.split(/\t/)[1]
  end

  def attribute_list
    attributes.split(',')
  end
end」






words_selector_test.rb
「require_relative 'words_selector'

words_selector = WordsSelector.new
text = "私は京都で働いたことがあります。"
result = words_selector.parse(text)
puts result.inspect」






words_selector.rb
「require 'suika'
require_relative 'word'

class WordsSelector
  def initialize
    @tagger = Suika::Tagger.new
  end
  attr_reader :tagger

  def self.select(words)
    words.select do |word|
      word.is_noun? || word.is_verb?
    end
  end
end」

words_splitter_test.rb
「require_relative 'words_splitter'

result = WordsSplitter.split('わたしは京都に来ています。')
puts result.inspect」






words_splitter.rb
「require 'suika'
require_relative 'word'

class WordsSplitter

  def self.split(text)
    @@tagger ||= Suika::Tagger.new
    array = @@tagger.parse(text)
    words = array.map do |line|
      Word.new(line)
    end
  end
end」






Gemfile
# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

# gem "rails"
gem 'suika'
gem 'nokogiri'






Gemfile.lock
 GEM
  remote: https://rubygems.org/
  specs:
    dartsclone (0.3.2)
    mini_portile2 (2.8.5)
    nokogiri (1.15.5)
      mini_portile2 (~> 2.8.2)
      racc (~> 1.4)
    racc (1.7.3)
    suika (0.3.2)
      dartsclone (>= 0.2.0)

PLATFORMS
  ruby

DEPENDENCIES
  nokogiri
  suika

BUNDLED WITH
   2.3.7
