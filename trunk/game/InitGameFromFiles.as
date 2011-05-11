package angel.game {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.LoaderWithErrorCatching;
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
			catalog.addEventListener(Event.COMPLETE, catalogLoadedListener);
			catalog.loadFromXmlFile("AngelCatalog.xml");
		}
		
		private function catalogLoadedListener(event:Event):void {
			Settings.catalog = Catalog(event.target);
			Settings.catalog.removeEventListener(Event.COMPLETE, catalogLoadedListener);
			Flags.loader.addEventListener(Event.COMPLETE, flagsLoadedListener);
			Flags.loadFlagListFromXmlFile();
		}
		
		private function flagsLoadedListener(event:Event):void {
			Flags.loader.removeEventListener(Event.COMPLETE, flagsLoadedListener);
			LoaderWithErrorCatching.LoadFile("AngelInit.xml", xmlLoadedForInit);
		}

		private function xmlLoadedForInit(event:Event, filename:String):void {
			var xmlData:XML = new XML(event.target.data);
			if (xmlData.room.length == 0) {
				Alert.show("ERROR: Bad init file! " + filename);
				return;
			}
			
			Settings.initFromXml(xmlData.settings);
			Settings.initPlayerFromXml(xmlData.player, Settings.catalog);
			Flags.initFlagsFromXml(xmlData.setFlag);
			
			callbackWithInitRoomXml(xmlData.room[0]);
		}
		
	}

}