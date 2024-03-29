package angel.game {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Util;
	import angel.game.event.QEvent;
	import angel.game.script.TriggerMaster;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InitGameFromFiles {
		private var initFinishedCallback:Function;
		private var initXml:XML = null;
		
		// Calls back with a SaveGame as parameter
		public function InitGameFromFiles(initFinishedCallback:Function):void {
			this.initFinishedCallback = initFinishedCallback;
			
			Settings.triggerMaster = new TriggerMaster();
			var catalog:Catalog = new Catalog();
			catalog.addEventListener(Event.INIT, catalogLoadedListener);
			catalog.loadFromXmlFile("AngelCatalog.xml");
			
			LoaderWithErrorCatching.LoadFile("AngelInit.xml", xmlLoadedForInit);
		}
		
		private function catalogLoadedListener(event:Event):void {
			event.target.removeEventListener(Event.INIT, catalogLoadedListener);
			Settings.catalog = Catalog(event.target);
			finishInitIfAllDataLoaded();
		}

		private function xmlLoadedForInit(event:Event, param:Object, filenameForErrors:String):void {
			initXml = Util.parseXml(event.target.data, filenameForErrors);
			if (initXml == null) {
				return;
			}
			if (initXml.room.length == 0) {
				Alert.show("ERROR: Bad init file! " + filenameForErrors);
				return;
			}
			finishInitIfAllDataLoaded();
		}
			
		private function finishInitIfAllDataLoaded():void {
			if ((Settings.catalog != null) && (initXml != null)) {
				Settings.initFromXml(initXml.settings);
				if (initXml.startScript.length() > 0) {
					Settings.initStartScript(initXml.startScript[0]);
				}
				var save:SaveGame = new SaveGame(true);
				save.initStartRoomFromXml(initXml.room);
				save.initPlayerInfoFromXml(initXml.player, Settings.catalog);
				Flags.initFlagsFromXml(initXml.setFlag);
				
				initFinishedCallback(save);
			}
		}
		
	}

}