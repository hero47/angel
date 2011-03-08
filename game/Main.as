package angel.game {
	import angel.common.*;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.geom.Rectangle;
	
	public class Main extends Sprite {
		private var catalog:Catalog;
		private var floor:Floor;
		private var testEntity:Entity;
		private var room:Room;
		private var startLoc:Point;
		private var entitiesToCreate:int;
		
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
		
		private function createTestEntity():Entity {
			[Embed(source='../../../assets/MA_mobile-barbara_4b.png')]
			var tempWalkerBits:Class;
			
			var bitmap:Bitmap = new tempWalkerBits();
			var entity:Walker = new Walker(new WalkerImage(bitmap.bitmapData));
			entity.solid = true;
			return entity;
		}
		
		private function addPropByName(propName:String, location:Point):void {
			++entitiesToCreate;
			catalog.retrieveBitmapData(propName, function(bitmapData:BitmapData):void {
				var prop:Entity = new Entity(new Bitmap(bitmapData));
				prop.solid = true;
				room.addEntity(prop, location);
				--entitiesToCreate;
				if (entitiesToCreate == 0) {
					finishedCreatingEntities();
				}
			});
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
			floor.addEventListener(Floor.MAP_LOADED_EVENT, mapLoadedListener);			
			floor.loadFromXml(xml.floor[0]);
		}
		

		private function mapLoadedListener(event:Event):void {
			floor.removeEventListener(Floor.MAP_LOADED_EVENT, mapLoadedListener);
			room = new Room(floor);
			addChild(room);
			room.scrollToCenter(startLoc, true);
			
			entitiesToCreate = 0;
			for each (var propXml:XML in contentsXml.prop) {
				var propName:String = propXml;
				addPropByName(propName, new Point(propXml.@x, propXml.@y));
			}
			
			// This callback will be processed BEFORE all the ones right above here adding props
			if (Settings.playerId == "") {
				room.addPlayerCharacter(createTestEntity(), startLoc);
			} else {
				catalog.retrieveBitmapData(Settings.playerId, function(bitmapData:BitmapData):void {
					var entity:Walker = new Walker(new WalkerImage(bitmapData));
					entity.solid = true;
					room.addPlayerCharacter(entity, startLoc);
				});
			}
			

		}

		private function finishedCreatingEntities():void {
			room.changeModeTo(RoomExplore);
		}
		
		// we take new size in parameters rather than retrieving from floor in case floor hasn't
		// finished loading yet when this is called
		public function initContentsFromXml(xml:XML):void {
		}
		
		
	}	// end class Main
}