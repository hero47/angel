package angel.game {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.Prop;
	import angel.common.PropImage;
	import angel.common.Util;
	import flash.display.Bitmap;
	import flash.geom.Point;
	
	public class SimpleEntity extends Prop {
		public var room:Room;

		
		public var aaId:String; // catalog id + arbitrary index, for debugging, at top of alphabet for easy seeing!
		private static var totalEntitiesCreated:int = 0;

		public function SimpleEntity(image:Bitmap, solidness: uint, id:String = "") {
			super(image);

			this.solidness = solidness;

			totalEntitiesCreated++;
			aaId = id + "-" + String(totalEntitiesCreated);
		}
		
		public static function createFromRoomContentsXml(propXml: XML, version:int, catalog:Catalog) : SimpleEntity {
			var id:String;
			
			//Delete older version support eventually
			if (version < 1) {
				id = propXml;
			} else {
				id = propXml.@id
			}
			
			var propImage:PropImage = catalog.retrievePropImage(id);
			var simpleEntity:SimpleEntity = new SimpleEntity(new Bitmap(propImage.imageData), propImage.solid, id);
			simpleEntity.myLocation = new Point(propXml.@x, propXml.@y);
			return simpleEntity;
		}

		override public function toString():String {
			return aaId + super.toString();
		}
		
		public function frobOk(player:ComplexEntity):Boolean {
			// Later, Wm has indicated that NPCs will be frobbable ("hail") from a greater distance, and there may be other
			// special cases.  Also, some entities may not be frobbable at all.
			return Util.chessDistance(player.location, myLocation) == 1;
		}
		
		// Eventually, entity properties and/or scripting will control what happens when entity is frobbed
		public function frob(player:ComplexEntity):void {
			Alert.show("It ignores you.");
		}
		
		//NOTE: indetermined yet whether it will be meaningful or useful to have an entity "in" a room but not
		//on the map. If we do support this, their location will be null.
		public function addToRoom(room:Room, newLocation:Point = null):void {
			this.room = room;
			if (newLocation != null) {
				this.location = newLocation;
			}
		}
		
		public function center():Point {
			return new Point(this.width / 2 + this.x, imageBitmap.height / 2 + imageBitmap.y + this.y);
		}

	}	
}