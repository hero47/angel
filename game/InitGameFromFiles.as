package angel.game {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Util;
	import angel.game.event.QEvent;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InitGameFromFiles {
		private var callbackWithInitRoomXml:Function;
		private var flagsLoaded:Boolean = false;
		private var xmlInitData:XML = null;
		
		public function InitGameFromFiles(callbackWithInitRoomXml:Function):void {
			this.callbackWithInitRoomXml = callbackWithInitRoomXml;
			
			var catalog:Catalog = new Catalog();
			catalog.addEventListener(Event.INIT, catalogLoadedListener);
			catalog.loadFromXmlFile("AngelCatalog.xml");
			
			Settings.gameEventQueue.addListener(this, Flags.flagLoader, QEvent.INIT, flagsLoadedListener);
			Flags.loadFlagListFromXmlFile();
			
			LoaderWithErrorCatching.LoadFile("AngelInit.xml", xmlLoadedForInit);
		}
		
		private function catalogLoadedListener(event:Event):void {
			event.target.removeEventListener(Event.INIT, catalogLoadedListener);
			Settings.catalog = Catalog(event.target);
			finishInitIfAllDataLoaded();
		}
		
		private function flagsLoadedListener(event:QEvent):void {
			Settings.gameEventQueue.removeListener(Flags.flagLoader, QEvent.INIT, flagsLoadedListener);
			flagsLoaded = true;
			finishInitIfAllDataLoaded();
		}

		private function xmlLoadedForInit(event:Event, filename:String):void {
			xmlInitData = Util.parseXml(event.target.data, filename);
			if (xmlInitData == null) {
				return;
			}
			if (xmlInitData.room.length == 0) {
				Alert.show("ERROR: Bad init file! " + filename);
				return;
			}
			finishInitIfAllDataLoaded();
		}
			
		private function finishInitIfAllDataLoaded():void {
			if ((Settings.catalog != null) && flagsLoaded && (xmlInitData != null)) {
				Settings.initFromXml(xmlInitData.settings);
				Settings.initPlayersFromXml(xmlInitData.player, Settings.catalog);
				Flags.initFlagsFromXml(xmlInitData.setFlag);
				
				callbackWithInitRoomXml(xmlInitData.room[0]);
			}
		}
		
	}

}