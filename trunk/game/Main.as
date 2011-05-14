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
			Settings.STAGE_HEIGHT = stage.stageHeight;
			Settings.STAGE_WIDTH = stage.stageWidth;
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
		
		private function roomXmlLoaded(event:Event, filename:String):void {
			var xml:XML = new XML(event.target.data);
			var room:Room = Room.createFromXml(xml, filename);
			if (room != null) {
				room.addPlayerCharactersFromSettings(startSpot);
				addChild(room);
				Settings.currentRoom = room;
				room.changeModeTo(RoomExplore);
			}
		}
		
	}	// end class Main
}