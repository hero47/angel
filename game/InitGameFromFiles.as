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
		
		public function InitGameFromFiles(callbackWithInitRoomXml:Function):void {
			this.callbackWithInitRoomXml = callbackWithInitRoomXml;
			var catalog:Catalog = new Catalog();
			catalog.addEventListener(Event.INIT, catalogLoadedListener);
			catalog.loadFromXmlFile("AngelCatalog.xml");
		}
		
		private function catalogLoadedListener(event:Event):void {
			Settings.catalog = Catalog(event.target);
			Settings.catalog.removeEventListener(Event.INIT, catalogLoadedListener);
			Settings.gameEventQueue.addListener(this, Flags.flagLoader, QEvent.INIT, flagsLoadedListener);
			Flags.loadFlagListFromXmlFile();
		}
		
		private function flagsLoadedListener(event:QEvent):void {
			Settings.gameEventQueue.removeListener(Flags.flagLoader, QEvent.INIT, flagsLoadedListener);
			LoaderWithErrorCatching.LoadFile("AngelInit.xml", xmlLoadedForInit);
		}

		private function xmlLoadedForInit(event:Event, filename:String):void {
			var xmlData:XML = Util.parseXml(event.target.data, filename);
			if (xmlData == null) {
				return;
			}
			if (xmlData.room.length == 0) {
				Alert.show("ERROR: Bad init file! " + filename);
				return;
			}
			
			Settings.initFromXml(xmlData.settings);
			Settings.initPlayersFromXml(xmlData.player, Settings.catalog);
			Flags.initFlagsFromXml(xmlData.setFlag);
			
			callbackWithInitRoomXml(xmlData.room[0]);
		}
		
	}

}