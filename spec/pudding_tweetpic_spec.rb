# This file is named after Pudding (@stawbewwi), because she made the things being tested here.
# twitter_ebooks does not come with free pudding. You should try a dessertery for that! :3

require 'spec_helper'
require 'tempfile'

module PuddiSpec
  module EbooksBot
    module Pic_
      class TestBot < Ebooks::Bot
        def configure
        end
      end
    end
  end
  module TweetPic
    LOWERCASE_LETTERS = [*'a'..'z']

    def random_letters(length, extra = [])
      length = [*length] if length.is_a? Range
      length = length.sample if length.is_a? Array
      extra |= LOWERCASE_LETTERS
      string = ''
      length.times do
        string += extra.sample
      end
      string
    end

    def random_filetype
      __::SUPPORTED_FILETYPES.values.uniq.sample
    end

    def make_file
      filetype = random_filetype
      file = __! :file, filetype
      file
    end

    def make_tempfile
      @_tempfiles ||= []
      filetype = random_filetype
      tempfile = Tempfile.new [random_letters(5..10), filetype]
      @_tempfiles << tempfile
      tempfile
    end

    def find_extension(filename)
      filename.match /(\.\w+)$/
      $1
    end

    def delete_files
      __.delete __.files
    end

    def close_tempfiles!
      return unless defined? @_tempfiles
      @_tempfiles.delete_if do |file|
        file.close!
        true
      end
    end

    def random_times(rand = 16..21)
      repeats = Random.rand(rand)
      repeats.times do
        yield
      end
      repeats
    end

    def __!(method, *args, &b)
      Ebooks::TweetPic.send(method, *args, &b)
    end
  end
end

describe Ebooks::Bot do
  describe '#pic_' do
    include PuddiSpec
    include PuddiSpec::EbooksBot::Pic_
  end
end

RSpec.shared_examples 'PuddiSpec/TweetPic/NoSuchFileError' do |method_name|
  it 'raises an error when a file doesn\'t exist' do
    expect do
      __! method_name, random_letters(5..25)
    end.to raise_error __::NoSuchFileError
  end
end

describe Ebooks::TweetPic do
  include PuddiSpec
  include PuddiSpec::TweetPic

  let :__ do
    Ebooks::TweetPic
  end

  let :__twitter do
    @__twitter ||= spy('twitter')
  end

  after :each do
    delete_files
    close_tempfiles!
  end

  describe :files do
    it 'returns an empty array before files have been made' do
      expect(__.files).to eq ([])
    end

    it 'returns an array containing the same number of files created' do
      repetitions = random_times do
        make_file
      end
      expect(__.files.length).to eq repetitions
    end
  end

  describe :file do
    it 'is private' do
      expect do
        __.file
      end.to raise_error NoMethodError
    end

    it 'creates empty files of supported filetypes' do
      filename = make_file
      filepath = __! :path, filename
      expect(File.size filepath).to eq 0
    end

    it 'doesn\'t create files of unsupported filetypes' do
      extensions = __::SUPPORTED_FILETYPES
      filetype = '.'
      loop do
        filetype = ".#{random_letters 3..5}"
        break unless extensions.include? filetype
      end
      expect { __! :file, filetype }.to raise_error __::FiletypeError
    end

    it 'creates files and virtual filenames with the same filetype as the requested filetype' do
      __::SUPPORTED_FILETYPES.keys.uniq.each do |filetype|
        filename = __! :file, filetype
        filepath = __! :path, filename
        cleaned_filetype = __::SUPPORTED_FILETYPES[filetype]
        expect(find_extension(filename)).to eq cleaned_filetype
        expect(find_extension(filepath)).to eq cleaned_filetype
      end
    end

    it 'creates a virtual filename of the correct format' do
      random_times do
        filename = make_file
        this_regex = /^\w+-\d+-\w+(\.\w+)$/
        expect(filename).to match this_regex
        this_regex.match filename
        expect(__::SUPPORTED_FILETYPES.values).to include($1)
      end
    end
  end

  describe :random_word do
    it 'is private' do
      expect do
        __.file
      end.to raise_error NoMethodError
    end

    it 'makes a random set of letters fitting requested criteria' do
      random_times do
        min_count = Random.rand(5..25)
        max_count = min_count + Random.rand(10..20)
        extra_characters = [*' '..'~']
        criteria = /[#{Regexp.escape extra_characters.join}]{#{min_count},#{max_count}}/
        expect(__! :random_word, min_count..max_count, extra_characters).to match criteria
      end
    end
  end

  describe :fetch do
    include_examples 'PuddiSpec/TweetPic/NoSuchFileError', :fetch

    it 'is private' do
      expect do
        __.file
      end.to raise_error NoMethodError
    end

    it 'returns a file object' do
      name = make_file
      expect(__! :fetch, name).to be_a File
    end

    it 'returns the same file' do
      name = make_file
      file = __! :fetch, name
      random_text = random_letters 32..64
      File.open file.path, 'w' do |this_file|
        this_file.write random_text
      end
      newfile = __! :fetch, name
      expect(newfile).to be file
      expect(File.read newfile.path).to eq random_text
    end
  end

  describe :path do
    include_examples 'PuddiSpec/TweetPic/NoSuchFileError', :path

    it 'is private' do
      expect do
        __.file
      end.to raise_error NoMethodError
    end

    it 'provides the same path as the one gotten from  :fetch,' do
      name = make_file
      file = __! :fetch, name
      expect(__! :path, name).to eq file.path
    end
  end

  describe :scheduler do
    it 'is private' do
      expect do
        __.file
      end.to raise_error NoMethodError
    end

    it 'gives a scheduler' do
      expect(__! :scheduler).to be_a Rufus::Scheduler
    end

    it 'gives the same scheduler' do
      scheduler = __! :scheduler
      expect(__! :scheduler).to be scheduler
    end
  end

  describe :delete do
    it 'removes files from #files' do
      random_times do
        make_file
      end
      __.delete __.files
      expect(__.files).to be_empty
    end

    it 'deletes the right files' do
      random_times do
        make_file
      end
      delete_file = __.files.sample
      __.delete delete_file
      expect(__.files).to_not include delete_file
    end

    it 'actually deletes files from disk' do
      name = make_file
      path = __! :path, name
      __.delete name
      expect(File.file? path).to be_falsy
    end

    it 'will queue up files it can\'t delete' # do
      # name = make_file
      # path = __! :path, name
      # File.open path do
        # expect(__.delete name).to include path
      # end
      # __! :scheduler.jobs.each(&:call)
      # expect(__.delete name).to_not include path
    # end

    it 'won\'t add non-existient files to its queue' do
      name = make_file
      path = __! :path, name
      File.delete path
      expect(__.delete name).to_not include path
    end
  end

  describe :download do
    it 'is private' do
      expect do
        __.file
      end.to raise_error NoMethodError
    end
  end

  describe :copy do
    it 'is private' do
      expect do
        __.file
      end.to raise_error NoMethodError
    end

    it 'copies files properly' do
      source = make_tempfile
      source.write random_letters 256..512
      source.close
      source_path = source.path
      destination = __! :copy, source_path
      destination_path = __! :path, destination
      source_contents = File.read source_path
      destination_contents = File.read destination_path
      expect(source_contents).to eq destination_contents
    end

    it 'creates empty files when passed just an extension' do
      name = __! :copy, random_filetype
      expect(File.size __!(:path, name)).to eq 0
    end
  end

  describe :get do
    it 'calls #download for http uris' do
      fake_uri = "http://#{random_letters 5..15}/#{random_letters 5..10}.#{random_filetype}"
      expect(__).to receive(:download)
      __.get fake_uri
    end

    it 'calls #download for https uris' do
      fake_uri = "https://#{random_letters 5..15}/#{random_letters 5..10}.#{random_filetype}"
      expect(__).to receive(:download)
      __.get fake_uri
    end

    it 'calls #copy for non uris' do
      fake_path = "#{random_letters 30..35, ['/']}.#{random_filetype}"
      expect(__).to receive(:copy)
      __.get fake_path
    end
  end

  describe :edit do
    include_examples 'PuddiSpec/TweetPic/NoSuchFileError', :edit

    it 'yields to a block' do
      name = make_file
      expect do |block|
        __.edit name, &block
      end.to yield_control
    end

    it 'raises an error when no block is given' do
      name = make_file
      expect do
        __.edit name
      end.to raise_error ArgumentError
    end

    it 'passes file path to block' do
      name = make_file
      path = __! :path, name
      expect do |block|
        __.edit name, &block
      end.to yield_with_args(path)
    end

    it 'makes persistient changes' do
      name = make_file
      contents = random_letters 64..256
      __.edit name do |path|
        file = File.open path, 'w'
        file.write contents
        file.close
      end
      expect(File.read __! :path, name).to eq contents
    end
  end

  describe :upload do
    it 'raises an error when a file doesn\'t exist' do
      expect do
        __.upload __twitter, random_letters(5..25)
      end.to raise_error __::NoSuchFileError
    end

    it 'raises an error when a file is empty' do
      name = make_file
      expect do
        __.upload __twitter, name
      end.to raise_error __::EmptyFileError
    end

    it 'passes the right arguments to twitter\'s #upload' do
      hash = {random_letters(5..10) => random_letters(15..25)}
      name = make_file
      path = __! :path, name
      File.open path, 'w' do |file|
        file.write random_letters 64..256
      end
      __.upload __twitter, name, hash
      expect(__twitter).to have_received(:upload).with kind_of(File), hash_including(hash) do |given_file, given_hash|
        expect(given_file.path).to eq path
      end
    end
  end

  describe :limit do
    it 'returns an integer when given no arguments' do
      expect(__.limit).to be_an Integer
    end

    it 'returns a difference when given an array argument' do
      count = Random.rand 16
      limit = __.limit
      expect(__.limit Array.new(count)).to equal(count - limit)
    end
  end
end

describe PuddiSpec::TweetPic do
  it 'is a completed _spec test' do
    expect(false).to be_true
  end
end