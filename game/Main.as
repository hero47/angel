package angel.game {
	import angel.common.*;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	
	// GAME Main class
	public class Main extends Sprite {
		private var catalog:Catalog;
		private var floor:Floor;
		private var testEntity:Entity;
		private var room:Room;
		private var startLoc:Point;
		
		public function Main() {
			stage.scaleMode = "noScale";

			Alert.init(stage);
			initFromXml();
		}
	
		private function initFromXml():void {
			catalog = new Catalog();
			catalog.addEventListener(Catalog.CATALOG_LOADED_EVENT, catalogLoadedListener);
			catalog.loadFromXmlFile("AngelCatalog.xml");
		}
		
		private function catalogLoadedListener(event:Event):void {
			catalog.removeEventListener(Catalog.CATALOG_LOADED_EVENT, catalogLoadedListener);
			LoaderWithErrorCatching.LoadFile("AngelInit.xml", xmlLoadedForInit);
		}

		private function xmlLoadedForInit(event:Event):void {
			var xmlData:XML = new XML(event.target.data);
			if (xmlData.room.length == 0) {
				Alert.show("ERROR: Bad init file!");
				return;
			}
			Settings.initFromXml(xmlData.settings);
			startLoc = new Point(xmlData.room.@startX, xmlData.room.@startY);
			LoaderWithErrorCatching.LoadFile(xmlData.room, roomXmlLoaded);
		}
		
		private var contentsXml:XML; // stash here for use in mapLoadedListener
		private function roomXmlLoaded(event:Event):void {
			var xml:XML = new XML(event.target.data);
			
			if (xml.floor.length() == 0) {
				Alert.show("Invalid room file.");
				return;
			}
			
			contentsXml = xml.contents[0];
			floor = new Floor();
			floor.addEventListener(Event.INIT, mapLoadedListener);			
			floor.loadFromXml(catalog, xml.floor[0]);
		}
		

		private function mapLoadedListener(event:Event):void {
			floor.removeEventListener(Event.INIT, mapLoadedListener);
			room = new Room(floor);
			addChild(room);
			room.scrollToCenter(startLoc, true);
			
			room.fillContentsFromXml(catalog, contentsXml);
			
			var entity:Walker = new Walker(catalog.retrieveWalkerImage(Settings.playerId));
			entity.solid = Prop.SOLID;
			room.addPlayerCharacter(entity, startLoc);
			
			room.changeModeTo(RoomExplore);
		}
		
		// we take new size in parameters rather than retrieving from floor in case floor hasn't
		// finished loading yet when this is called
		public function initContentsFromXml(xml:XML):void {
		}
		
		
	}	// end class Main
}