package angel.game {
	import angel.common.*;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Main extends Sprite {
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
			floor = new Floor();
			floor.addEventListener(Floor.MAP_LOADED_EVENT, mapLoadedListener);
			floor.loadFloorFromXmlFile(xmlData.room);
		}
		
		private function createTestEntity():Entity {
			[Embed(source='../../../assets/MA_mobile-barbara_4b.png')]
			var tempWalker:Class;
			
			var bitmap:Bitmap = new tempWalker();
			var entity:Walker = new Walker(new WalkerImage(bitmap));
			return entity;
		}

		private function createCrate():Entity {
			[Embed(source='../../../assets/lw-crate3.png')]
			var tempCrate:Class;
			
			var bitmap:Bitmap = new tempCrate();
			var entity:Entity = new Entity(bitmap);
			entity.solid = true;
			return entity;
		}

		private function createPillar():Entity {
			[Embed(source='../../../assets/MA_lw-pillar2.png')]
			var tempPillar:Class;
			
			var bitmap:Bitmap = new tempPillar();
			var entity:Entity = new Entity(bitmap);
			entity.solid = true;
			return entity;
		}
		

		private function mapLoadedListener(event:Event):void {
			floor.removeEventListener(Floor.MAP_LOADED_EVENT, mapLoadedListener);
			room = new Room(floor);
			addChild(room);
			room.scrollToCenter(startLoc, true);
			room.addPlayerCharacter(createTestEntity(), startLoc);
			room.addEntity(createCrate(), new Point(1,0));
			room.addEntity(createCrate(), new Point(1,1));
			room.addEntity(createCrate(), new Point(0,1));
			room.addEntity(createPillar(), new Point(4, 2));
			room.addEntity(createPillar(), new Point(4, 3));
			room.addEntity(createPillar(), new Point(4, 4));
		}
		
	}	// end class Main
}