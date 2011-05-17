package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.Util;
	import angel.game.action.ConversationAction;
	import angel.game.script.ConversationData;
	import angel.game.script.Script;
	import flash.display.Bitmap;
	import flash.geom.Point;
	
	public class SimpleEntity extends Prop {
		public var room:Room;
		public var id:String;
		
		public var frobScript:Script;

		
		public var aaId:String; // catalog id + arbitrary index, for debugging, at top of alphabet for easy seeing!
		private static var totalEntitiesCreated:int = 0;

		public function SimpleEntity(image:Bitmap, solidness: uint, id:String = "") {
			super(image);
			this.id = id;
			this.solidness = solidness;

			totalEntitiesCreated++;
			aaId = id + "-" + String(totalEntitiesCreated);
		}
		
		override public function cleanup():void {
			Assert.fail("See comment on SimpleEntity.detachFromRoom");
		}
		
		public function detachFromRoom():void {
			//UNDONE: when we add resource tracking, this will probably be messed up!  When player character is removed
			//from room, we keep a reference to it in Settings; when other entity is removed, we should free its
			//resources.  Currently we don't distinguish between those two cases.
			if (room != null) {
				room = null;
			}
			if (parent != null) {
				parent.removeChild(this);
			}
		}
		
		public static function createFromRoomContentsXml(propXml: XML, version:int, catalog:Catalog) : SimpleEntity {
			var id:String;
			
			//Delete older version support eventually
			if (version < 1) {
				id = propXml;
			} else {
				id = propXml.@id
			}
			
			var resource:RoomContentResource = catalog.retrievePropResource(id);
			var simpleEntity:SimpleEntity = new SimpleEntity(new Bitmap(resource.standardImage()), resource.solidness, id);
			simpleEntity.setCommonPropertiesFromXml(propXml);
			return simpleEntity;
		}
		
		public function setCommonPropertiesFromXml(xml:XML):void {
			if ((String(xml.@x) != "") || (String(xml.@y) != "")) {
				myLocation = new Point(xml.@x, xml.@y);
			}
			var scriptFile:String = xml.@script;
			
			//UNDONE: @talk is pre-5/13/11 version; get rid of this eventually
			var talk:String = xml.@talk;
			if (talk != "") {
				if (scriptFile != "") {
					Alert.show("Error! @talk and @script on same room item, id " + id);
				}
				var conversationData:ConversationData = new ConversationData();
				conversationData.loadFromXmlFile(talk);
				frobScript = new Script();
				frobScript.addAction(new ConversationAction(conversationData, Script.TRIGGERING_ENTITY_ID));
			}
			
			if (scriptFile != "") {
				frobScript = new Script();
				frobScript.loadFromXmlFile(scriptFile);
			}
		}
		
		public function get displayName():String {
			return null;
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
			if (frobScript != null) {
				frobScript.run(this);
			} else {
				var nameOrIt:String = displayName;
				if ((nameOrIt == null) || (nameOrIt == "")) {
					nameOrIt = "It";
				}
				Alert.show(nameOrIt + " ignores you.");
			}
		}
		
		//NOTE: indetermined yet whether it will be meaningful or useful to have an entity "in" a room but not
		//on the map. If we do support this, their location will be null.
		public function addToRoom(room:Room, newLocation:Point = null):void {
			this.room = room;
			if (newLocation != null) {
				this.location = newLocation;
			}
			dispatchEvent(new EntityEvent(EntityEvent.ADDED_TO_ROOM, true, false, this));
		}
		
		public function centerOfImage():Point {
			return new Point(this.width / 2 + this.x, imageBitmap.height / 2 + imageBitmap.y + this.y);
		}

	}	
}