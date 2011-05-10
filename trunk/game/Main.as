package angel.game {
	import angel.common.*;
	import angel.game.brain.BrainFollow;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	import flash.utils.describeType;
	
	
	// GAME Main class
	public class Main extends Sprite {
		private var catalog:Catalog;
		private var floor:Floor;
		private var room:Room;
		private var startSpot:String;
		
		public function Main() {
			stage.scaleMode = "noScale";
			Settings.FRAMES_PER_SECOND = stage.frameRate;
			Alert.init(stage);
			
			initFromXml();
		}
	
		private function initFromXml():void {
			catalog = new Catalog();
			catalog.addEventListener(Event.COMPLETE, catalogLoadedListener);
			catalog.loadFromXmlFile("AngelCatalog.xml");
		}
		
		private function catalogLoadedListener(event:Event):void {
			catalog.removeEventListener(Event.COMPLETE, catalogLoadedListener);
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
				Alert.show("ERROR: Bad init file!");
				return;
			}
			
			Settings.initFromXml(xmlData.settings);
			Settings.initPlayerFromXml(xmlData.player, catalog);
			Flags.initFlagsFromXml(xmlData.setFlag);
			
			
			startSpot = xmlData.room.@start;
			
			LoaderWithErrorCatching.LoadFile(xmlData.room, roomXmlLoaded);
		}
		
		private var roomXml:XML; // stash here for use in mapLoadedListener
		private function roomXmlLoaded(event:Event, filename:String):void {
			var xml:XML = new XML(event.target.data);
			
			if (xml.floor.length() == 0) {
				Alert.show("Invalid room file.");
				return;
			}
			
			roomXml = xml;
			floor = new Floor();
			floor.addEventListener(Event.INIT, mapLoadedListener);			
			floor.loadFromXml(catalog, xml.floor[0]);
		}
		

		private function mapLoadedListener(event:Event):void {
			floor.removeEventListener(Event.INIT, mapLoadedListener);
			room = new Room(floor);
			addChild(room);
			Settings.currentRoom = room;
			Settings.catalog = catalog;
			
			if (roomXml.contents.length() > 0) {
				room.initContentsFromXml(catalog, roomXml.contents[0]);
			}
			if (roomXml.spots.length() > 0) {
				room.initSpotsFromXml(roomXml.spots[0]);
			}
			
			var startLoc:Point;
			if ((startSpot == null) || (startSpot == "")) {
				startLoc = new Point(0, 0);
			} else {
				startLoc = room.spots[startSpot];
			}
			room.snapToCenter(startLoc);
			var previousPc:String = null;
			for each (var entity:ComplexEntity in Settings.pcs) {
				// UNDONE: start followers near main PC instead of stacked on top
				room.addPlayerCharacter(entity, startLoc);
				if (previousPc != null) {
					entity.exploreBrainClass = BrainFollow;
					entity.exploreBrainParam = previousPc;
				}
				previousPc = entity.id;
			}
			
			room.changeModeTo(RoomExplore);
		}
		
		
	}	// end class Main
}