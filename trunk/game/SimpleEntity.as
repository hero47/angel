package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.Util;
	import angel.game.action.ConversationAction;
	import angel.game.event.EntityQEvent;
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
			
			if (xml.@script.length() > 0) {
				if (scriptFile == "") {
					frobScript = null;
				} else {
					frobScript = new Script();
					frobScript.loadFromXmlFile(scriptFile);
				}
			}
		}
		
		public function get displayName():String {
			return null;
		}

		override public function toString():String {
			return aaId + super.toString();
		}
		
		public function frobOk(whoFrobbedMe:ComplexEntity):Boolean {
			var maxDistance:int = (this is ComplexEntity) ? 2 : 1;
			return Util.chessDistance(whoFrobbedMe.location, myLocation) <= maxDistance;
		}
		
		// NOTE: The frob-ee is passed to the script for reference by "*this".
		public function frob(whoFrobbedMe:ComplexEntity):void {
			if (!frobOk(whoFrobbedMe)) {
				//NOTE: currently (5/17/11) shouldn't ever get here -- UI will only call frob if frobOk is true.
				//We may change that, either frob anyway (and get here), or make clicking on a too-far-away object
				//cause the player to attempt to walk up to frobbing distance and then frob. (Complicated, user-friendly
				//for majority cases, but horribly not-what-I-meant!-unfriendly for some cases.)
				Alert.show("Too far away.");
				return;
			}
			if (frobScript != null) {
				frobScript.run(this.room, this);
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
			Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.ADDED_TO_ROOM));
		}
		
		public function centerOfImage():Point {
			return new Point(this.width / 2 + this.x, imageBitmap.height / 2 + imageBitmap.y + this.y);
		}

	}	
}