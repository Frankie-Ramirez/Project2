package
{
	import com.Zambie.FlashBoard.Interface.Plugin;
	import com.Zambie.FlashBoard.UI.ConfigurationDBox;
	import com.jworkman.Effects.Fade;
	
	import flash.display.Loader;
	import flash.display.LoaderInfo;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.TimerEvent;
	import flash.filesystem.File;
	import flash.filesystem.FileMode;
	import flash.filesystem.FileStream;
	import flash.net.FileFilter;
	import flash.net.URLRequest;
	import flash.system.LoaderContext;
	import flash.utils.ByteArray;
	import flash.utils.Timer;
	import flash.utils.getDefinitionByName;
	
	
	public class FlashBoard extends Sprite
	{
		
		private var _setupMenu:ConfigurationDBox;
		private var _xmlFilePath:String;
		private var _xmlReloadDuration:uint;
		private var _xmlData:XML;
		private var _defaultSlideTime:uint;
		private var _slideTimer:Timer;
		private var _xmlTimer:Timer;
		private var _fader:Fade;
		private var _currentSlide:int = 0;
		
		private var _plugins:Array =[];
		private var _pluginXML:Array = [];
		private var _pluginConfigurations:Array = [];
		
		private var pluginList:Object;
		
		public function FlashBoard()
		{
			
			startUpUI();
			
		}
		
		private function startUpUI():void {
			pluginList = {};
			
			
			_setupMenu = new ConfigurationDBox();
			_setupMenu.addEventListener(ConfigurationDBox.CONFIGURATION_COMPLETE, onConfigurationComplete);
			this.addChild(_setupMenu);
			_setupMenu.x = this.stage.stageWidth/2;
			_setupMenu.y = this.stage.stageHeight/2;
			_setupMenu.initUI();
			
		}
		
		private function onConfigurationComplete(e:Event):void {
			
			_xmlFilePath = _setupMenu.filePath;
			_xmlReloadDuration = _setupMenu.reloadDuration;
			
			
			
			if (_xmlReloadDuration) {
				
				loadXML();
				
			} 
			
		}
		
		private function loadXML():void {
			
			var file:File = new File(_xmlFilePath);
			var fs:FileStream = new FileStream();
			fs.open(file, FileMode.READ);
			var str:String = fs.readUTFBytes(fs.bytesAvailable);
			fs.close();
			_xmlData = XML(str);
			
			_defaultSlideTime = uint(_xmlData.configuration.slides.time);
			
			if (_defaultSlideTime) {
				
				loadPlugins();
				
			}
			
		}
		
		private function loadPlugins():void {
			for each(var pluginNode:XML in _xmlData.plugins.plugin) {
				//var file:File = File.desktopDirectory;
				var file:File = File.desktopDirectory.resolvePath(pluginNode.filename);
			
				pluginList[pluginNode.filename] = pluginNode;
				//file.resolvePath(pluginNode.filename);
				
			
				var fs:FileStream = new FileStream();
				fs.open(file, FileMode.READ);
				var ba:ByteArray = new ByteArray();
			
				fs.readBytes(ba);
				fs.close();
			
				var loaderContext:LoaderContext = new LoaderContext();
				loaderContext.allowLoadBytesCodeExecution = true;
			
				var l:Loader = new Loader();
				l.loadBytes(ba,loaderContext);
				l.contentLoaderInfo.addEventListener(Event.COMPLETE, onPluginLoadComplete);
			}
			
			initSlideShow();
			
		}
		
		private function onPluginLoadComplete(e:Event):void {
			
			var plugin:Plugin = e.currentTarget.content as Plugin;
			
			
			
			var pluginXML:XML = XML(pluginList[plugin.fileName].data);
			
			trace(pluginXML);
			
			plugin.init(pluginXML);
			
			_plugins.push(plugin);
			
			addChild(plugin);
			
			
			
			
		}
		
		private function initSlideShow():void {
			
			for each(var plugin:Plugin in _plugins) {
				
				plugin.addEventListener(Plugin.TIME_DONE, onSlideDone);
				
			}
			
			onSlideDone(new Event(Plugin.TIME_DONE));
			
		}
		
		private function onSlideDone(e:Event):void {
			
			
			if(_plugins[_currentSlide])
			{
				(_plugins[_currentSlide] as Plugin).disconnect();
			}
			
			if (_currentSlide >= _plugins.length - 1) {
				
				_currentSlide = 0;
				
			} else {
				
				_currentSlide++;
				
			}
			
			if(_plugins[_currentSlide])
			{
				(_plugins[_currentSlide] as Plugin).connect();
			}
			
		}
		
		
		
		private function initClock():void {
			
			
			
			_plugins[_plugins.length - 1].alpha = 1;
			_plugins[_plugins.length - 1].scaleX = _plugins[_plugins.length - 1].scaleY = .35;
			_plugins[_plugins.length - 1].x = this.stage.stageWidth - 120;
			_plugins[_plugins.length - 1].y = this.stage.stageHeight - 100;
			
			
		}
		
		
		
		
	}
}