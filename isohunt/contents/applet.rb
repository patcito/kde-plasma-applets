require 'plasma_applet'

module Isohunt
class Applet < PlasmaScripting::Applet
	
	class Pager < Qt::GraphicsWidget
		
		signals 'previousPage()', 'nextPage()'
		
		def initialize( parent )
			super parent
			@page = 0
			layout = Qt::GraphicsLinearLayout.new Qt::Horizontal
			setLayout layout
			previousPage = Plasma::IconWidget.new KDE::Icon.new('arrow-left'), '', self
			nextPage = Plasma::IconWidget.new KDE::Icon.new('arrow-right'), '', self
			[previousPage,nextPage].each do |icon| layout.addItem icon end
			connect previousPage, SIGNAL('clicked()'), self, SIGNAL('previousPage()')
			connect nextPage, SIGNAL('clicked()'), self, SIGNAL('nextPage()')
		end
		
	end
	
	class ItemRow < Qt::GraphicsWidget
		
		slots :openTorrent, 'openDetails(const QString&)'
		
		def initialize( parent, data )
			super parent
			@data = {}
			@layout = Qt::GraphicsLinearLayout.new
			@layout.orientation = Qt::Horizontal
			setLayout @layout
			@layout.addItem label(data)
# 			@layout.addStretch
			@layout.addItem action(data)
# 			setSizePolicy Qt::SizePolicy.new(Qt::SizePolicy::Expanding,Qt::SizePolicy::Expanding)
		end
		
		def label(data)
			unless @label
				@label = Plasma::Label.new self
				connect @label, SIGNAL('linkActivated(const QString&)'),
						self, SLOT('openDetails(const QString&)')
			end
			@label.setText "#{data['title']} <a href=\"#{data['link']}\">details</a>"
			@label
		end
		
		def action(data)
			unless @icon
				@icon = Plasma::IconWidget.new(
					KDE::Icon.new('preferences-desktop-wallpaper'),'', self )
				connect @icon, SIGNAL('clicked()'), self, SLOT('openTorrent()')
				@layout.setAlignment @icon, Qt::AlignRight
			end
			@data[@icon]=data['enclosure_url']
			@icon
		end
		
		def setup(data)
			label(data)
			action(data)
		end
		
		def openTorrent
			KDE::Run.runUrl KDE::Url.new(@data[sender]),'application/x-bittorrent', nil
		end
		
		def openDetails( url )
			KDE::Run.runUrl KDE::Url.new(url), 'text/html', nil
		end
	end
	
	slots :submit, 'getResult(KJob*)', :previousPage, :nextPage
	
	def initialize( parent, args = nil )
# 		GC.disable
		super
		@page = 0
		@items = []
# 		ignore = Qt::SizePolicy.new Qt::SizePolicy::Ignored,Qt::SizePolicy::Ignored
		setAspectRatioMode Plasma::IgnoreAspectRatio
		@layout = Qt::GraphicsLinearLayout.new
		@layout.orientation = Qt::Vertical
		queryLayout = Qt::GraphicsLinearLayout.new
		queryLayout.orientation = Qt::Horizontal
# 		queryLayout.sizePolicy = ignore
		@lineEdit = Plasma::LineEdit.new self
		submit = Plasma::IconWidget.new KDE::Icon.new('edit-find'),'',self
		connect submit, SIGNAL('clicked()'), self, SLOT('submit()')
		@queryFrame = Plasma::Frame.new self
		queryLayout.addItem @lineEdit
		queryLayout.addItem submit
		@queryFrame.layout = queryLayout
		@layout.addItem @queryFrame
		@dataFrame = Plasma::Frame.new self
		@dataLayout = Qt::GraphicsLinearLayout.new
		@dataLayout.orientation = Qt::Vertical
		@dataFrame.layout = @dataLayout
		spacer = Qt::GraphicsWidget.new
		@dataLayout.addItem spacer
		@dataLayout.insertItem 9000, spacer
		@layout.addItem @dataFrame
		@layout.setStretchFactor @dataFrame, 99
		@resultsLabel = Plasma::Label.new self
		@resultsLabel.text = 'tantos resultados'
		@layout.addItem @resultsLabel
		@layout.setStretchFactor @resultsLabel, 1
		@pager = Pager.new self
		@layout.addItem @pager
		@layout.setStretchFactor @pager, 1
		connect @pager, SIGNAL('previousPage()'), self, SLOT('previousPage()')
		connect @pager, SIGNAL('nextPage()'), self, SLOT('nextPage()')
		setLayout @layout
# 		puts 'isoHunt applet initialized'
	end
	
	def init
		puts 'isoHunt applet init'
		begin
			begin
				require 'json'
			rescue LoadError
				require 'rubygems'
				require 'json'
			end
		rescue LoadError
			setFailedToLaunch true, 'Could not find JSON library'
		end
		Qt.debug_level = 2
	end
	
	def query
		url = KDE::Url.new 'http://isohunt.com/js/json.php'
		url.addQueryItem 'ihq', @lineEdit.text
		url.addQueryItem 'start', start.to_s
		url.addQueryItem 'rows', rows.to_s
		url.addQueryItem 'sort', 'seeds' if sortByPeers
		url.addQueryItem 'noSL', '' if noSL
		puts url.url
		url
	end
	
	def start
		rows * @page + 1
	end
	
	def rows
		15
	end
	
	def sortByPeers
		false
	end
	
	def noSL
		false
	end
	
	def pages
		( @totalResults / rows ) + ( @totalResults % rows == 0 ? 1 : 0 )
	end
	
	def submit
		job = KIO::storedGet query, KIO.Reload, KIO.HideProgressInfo
		connect job, SIGNAL('result(KJob*)'), self, SLOT('getResult(KJob*)')
	end
	
	def getResult( job )
		job = job.qobject_cast KIO::StoredTransferJob
		data = job.data.to_s
		unless data.empty?
			data = JSON.parse data
			display data
		end
	end
	
	def display( data )
		setTotalResults data[ 'total_results' ]
		if @totalResults > 0
			addItems data[ 'items' ][ 'list' ]
		end
		deleteRemainingItems
	end
	
	def addItems( data )
		recycleTop = [ @items.size, @totalResults ].min
		recycleTop.times do |index|
			@items[index].setup data[index]
		end
		if recycleTop < @totalResults
			(recycleTop...data.size).each do |index|
				@items << (item=createItem(data[index]))
				addItem item, index
			end
		end
	end
	
	def createItem( data )
		ItemRow.new self, data
	end
	
	def addItem( item, index = -1 )
		@dataLayout.insertItem index, item#, index
	end
	
	def setupItem( item, data )
		item.setup data
	end
	
	def setTotalResults( n = 0 )
		@totalResults = n
		@resultsLabel.text = "Total results: #{n}"
	end
	
	def deleteRemainingItems
		(@totalResults...@items.size).each do |index|
			item = @items[index]
			@dataLayout.removeItem item
			@items[index] = nil
			item.dispose
		end
	end
	
	def previousPage
		unless @page <= 0
			@page -= 1
			submit
		end
	end
	
	def nextPage
		unless pages <= @page
			@page += 1
			submit
		end
	end
	
end
end
