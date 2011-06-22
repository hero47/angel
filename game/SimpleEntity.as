package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.Prop;
	import angel.common.PropResource;
	import angel.common.Util;
	import angel.game.event.EntityQEvent;
	import angel.game.script.action.ConversationAction;
	import angel.game.script.ConversationData;
	import angel.game.script.EntityTriggers;
	import angel.game.script.Script;
	import angel.game.script.TriggerMaster;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.geom.Point;
	
	public class SimpleEntity extends Prop {
		public var room:Room;
		public var id:String;
		
		public var frobScript:Script;
		public var triggers:EntityTriggers;
		public var hasFrobScript:Boolean;
		
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
			if (room != null) {
				room = null;
			}
			if (triggers != null) {
				triggers.cleanup();
				triggers = null;
			}
			super.cleanup();
		}
		
		public static function createFromRoomContentsXml(propXml:XML, catalog:Catalog):SimpleEntity {
			var id:String;
			
			id = propXml.@id;
			
			var resource:PropResource = catalog.retrievePropResource(id);
			var simpleEntity:SimpleEntity = new SimpleEntity(new Bitmap(resource.standardImage()), resource.solidness, id);
			simpleEntity.setCommonPropertiesFromXml(propXml);
			return simpleEntity;
		}
		
		public function setCommonPropertiesFromXml(xml:XML):void {
			if ((String(xml.@x) != "") || (String(xml.@y) != "")) {
				myLocation = new Point(xml.@x, xml.@y);
			}
			
			if (xml.@script.length() > 0) {
				var scriptFile:String = xml.@script;
				if (scriptFile != "") {
					if (triggers != null) {
						triggers.cleanup();
					}
					triggers = new EntityTriggers(this, scriptFile);
				}
			}
		}
		
		public function addCommonPropertiesToXml(xml:XML):void {
			xml.@id = id;
			xml.@x = myLocation.x;
			xml.@y = myLocation.y;
			if (triggers != null) {
				xml.@script = triggers.scriptFile;
			}
		}
		
		public function appendXMLSaveInfo(contentsXml:XML):void {
			var xml:XML = <prop />;
			addCommonPropertiesToXml(xml);
			contentsXml.appendChild(xml);
		}
		
		public function get displayName():String {
			return null;
		}
		
		public function portraitBitmapData():BitmapData {
			return null;
		}

		override public function toString():String {
			return aaId + super.toString();
		}
		
		public function frobOk(whoFrobbedMe:ComplexEntity):Boolean {
			return Util.chessDistance(whoFrobbedMe.location, myLocation) <= 1;
		}
		
		// If frobbing the entity gives choices, return pie slices for those choices.
		// Otherwise, carry out the frob and return null.
		// NOTE: The frob-ee is passed to the script for reference by "*it".
		public function frob(whoFrobbedMe:ComplexEntity):Vector.<PieSlice> {
			if (!frobOk(whoFrobbedMe)) {
				//NOTE: currently (5/17/11) shouldn't ever get here -- UI will only call frob if frobOk is true.
				//We may change that, either frob anyway (and get here), or make clicking on a too-far-away object
				//cause the player to attempt to walk up to frobbing distance and then frob. (Complicated, user-friendly
				//for majority cases, but horribly not-what-I-meant!-unfriendly for some cases.)
				Alert.show("Too far away.");
				return null;
			}
			if (hasFrobScript) {
				Settings.gameEventQueue.dispatch(new EntityQEvent(this, EntityQEvent.FROBBED, whoFrobbedMe));
			} else {
				var nameOrIt:String = displayName;
				if (Util.nullOrEmpty(nameOrIt)) {
					nameOrIt = "It";
				}
				Alert.show(nameOrIt + " ignores you.");
			}
			return null
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