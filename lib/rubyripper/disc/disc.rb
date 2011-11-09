#!/usr/bin/env ruby
#    Rubyripper - A secure ripper for Linux/BSD/OSX
#    Copyright (C) 2007 - 2010  Bouke Woudstra (boukewoudstra@gmail.com)
#
#    This file is part of Rubyripper. Rubyripper is free software: you can
#    redistribute it and/or modify it under the terms of the GNU General
#    Public License as published by the Free Software Foundation, either
#    version 3 of the License, or (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>

require 'rubyripper/disc/scanDiscCdparanoia'
require 'rubyripper/disc/calcFreedbID'
require 'rubyripper/disc/calcMusicbrainzID'
require 'rubyripper/system/dependency'

# A helper class to hide lower level details
class Disc
attr_reader :metadata

  def initialize(cdpar=nil, freedb=nil, musicbrainz=nil, deps=nil, prefs=nil)
    @cdparanoia = cdpar ? cdpar : ScanDiscCdparanoia.new()
    @calcFreedbID = freedb ? freedb : CalcFreedbID.new(self)
    @calcMusicbrainzID = musicbrainz ? musicbrainz : CalcMusicbrainzID.new(self)
    @deps = deps ? deps : Dependency.instance
    @prefs = prefs ? prefs : Preferences::Main.instance
  end
  
  # scan the disc for a drive
  def scan(metadata=nil)
    @cdparanoia.scan()
    setMetadata(metadata) if @cdparanoia.status == 'ok'
  end
  
  # return the object that is used for calculating the freedb string
  def tocScannerForFreedbString(cdinfo=nil, cdcontrol=nil)
    if @deps.installed?('cd-info')
      require 'rubyripper/disc/scanDiscCdinfo'
      scanner = cdinfo ? cdinfo : ScanDiscCdinfo.new()
    elsif @deps.installed?('cdcontrol')
      require 'rubyripper/disc/scanDiscCdcontrol'
      scanner = cdcontrol ? cdcontrol : ScanDiscCdcontrol.new()
    else
      scanner = @cdparanoia
    end
    
    return scanner
  end
  
  # helper functions for @freedb
  def freedbString ; @calcFreedbID.freedbString ; end
  def discid ; @calcFreedbID.discid; end

  # helper functions for @musicbrainz
  def musicbrainzLookupPath ; @calcMusicbrainzID.musicbrainzLookupPath ; end
  def musicbrainzDiscid ; @calcMusicbrainzID.discid ; end

  private
  
  # if the method is not found try to look it up in cdparanoia
  def method_missing(name, *args)
    @cdparanoia.send(name, *args)
  end

  # helper function to load metadata object
  def setMetadata(metadata=nil)
    provider = @prefs.metadataProvider
    if provider == 'musicbrainz'
      require 'rubyripper/metadata/musicbrainz'
      @metadata = metadata ? metadata : MusicBrainz.new(self)
      @metadata.get()
    end
    
    if provider == 'freedb' || @metadata.status != 'ok'
      require 'rubyripper/metadata/freedb'
      @metadata = metadata ? metadata : Freedb.new(self)
      @metadata.get()
    elsif provider == 'none'
      # TODO
    end
  end
end

# private
#
# 	# use cdrdao to scan for exact pregaps, hidden tracks, pre_emphasis
# 	def prepareToc
# 		if @settings['create_cue'] && @deps.installed?('cdrdao')
# 			@cdrdaoThread = Thread.new{advancedToc()}
# 		elsif @settings['create_cue']
# 			puts "Cdrdao not found. Advanced TOC analysis / cuesheet is skipped."
# 			@settings['create_cue'] = false # for further assumptions later on
# 		end
# 	end
#
# 	# start the Advanced toc instance
# 	def advancedToc
# 		@tocStarted = true
# 		@toc = ScanDiscCdrdao.new(@settings)
# 	end
#
# 	# update the Disc class with actual settings and make a cuesheet
# 	def updateSettings(settings)
# 		@settings = settings
#
# 		# user may have enabled cuesheet after the disc was scanned
# 		# @toc is still nil because the class isn't finished yet
# 		prepareToc() if @tocStarted == false
#
# 		# if the scanning thread is still active, wait for it to finish
# 		@cdrdaoThread.join() if @cdrdaoThread != nil
#
# 		# update the length of the sectors + the start of the tracks if we're
# 		# prepending the gaps
# 		# also for the image since this is more easy with the cuesheet handling
# 		if @settings['pregaps'] == "prepend" || @settings['image']
# 			prependGaps()
# 		end
#
# 		# only make a cuesheet when the toc class is there
# 		@cue = Cuesheet.new(@settings, @toc) if @toc != nil
# 	end
# endrequire 'rubyripper/disc'
#
# #		if @disc.freedbString != @disc.oldFreedbString # Scanning the same disc will always result in an new freedb fetch.
# #			if @metadataFile.has_key?(@disc.freedbString) || findLocalMetadata #is the Metadata somewhere local?
# #				if @metadataFile.has_key?(@disc.freedbString)
# #					@rawResponse = @metadataFile[@disc.freedbString]
# #				end
# #				@tracklist.clear()
# #				handleResponse()
# #				@status = true # Give the signal that we're finished
# #				return true
# #			end
# #		end
# #
# #		if @verbose ; puts "preparing to contact freedb server" end
# #		handshake()
# #	end
