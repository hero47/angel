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
		private var floor:Floor;
		private var room:Room;
		private var startSpot:String;
		
		public function Main() {
			stage.scaleMode = "noScale";
			Settings.FRAMES_PER_SECOND = stage.frameRate;
			Alert.init(stage);
			
			new InitGameFromFiles(gameInitialized);
		}
		
		private function gameInitialized(initRoomXml:XML):void {
			startSpot = initRoomXml.@start;
			var roomFile:String = initRoomXml.@file;
			if (roomFile == "") {
				roomFile = initRoomXml;
				Alert.show("Warning: Init file 'room' format changing.\nPlease move room filename into file attribute.");
			}
			if (roomFile == "") {
				Alert.show("Error! Missing filename for initial room.");
				return;
			}
			LoaderWithErrorCatching.LoadFile(roomFile, roomXmlLoaded);
		}
		
		private var roomXml:XML; // stash here for use in mapLoadedListener
		private function roomXmlLoaded(event:Event, filename:String):void {
			var xml:XML = new XML(event.target.data);
			
			if (xml.floor.length() == 0) {
				Alert.show("Invalid room file " + filename);
				return;
			}
			
			roomXml = xml;
			floor = new Floor();
			floor.addEventListener(Event.INIT, mapLoadedListener);			
			floor.loadFromXml(Settings.catalog, xml.floor[0]);
		}
		

		private function mapLoadedListener(event:Event):void {
			floor.removeEventListener(Event.INIT, mapLoadedListener);
			room = new Room(floor);
			addChild(room);
			Settings.currentRoom = room;
			
			if (roomXml.contents.length() > 0) {
				room.initContentsFromXml(Settings.catalog, roomXml.contents[0]);
			}
			if (roomXml.spots.length() > 0) {
				room.initSpotsFromXml(roomXml.spots[0]);
			}
			
			var startLoc:Point;
			if ((startSpot == null) || (startSpot == "")) {
				startSpot = "start";
			}
	
			startLoc = room.spotLocationWithDefault(startSpot);
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