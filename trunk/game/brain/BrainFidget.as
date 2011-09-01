package angel.game.brain {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.RoomExplore;
	import angel.game.SimpleEntity;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	/* "The NPC should be placed in the scene, facing in a random direction; they should then turn to face another
	 * direction, intermittently, in a random direction.  At this point, no more than twice in a row; with a wait
	 * of a second between chances to turn; and no more than ¼ of the time will they move."
	 */
	public class BrainFidget implements IBrain {
		private var me:ComplexEntity;
		private var getFacingFunction:Function = randomFacing;
		private var spotTarget:Point;
		private var entityTarget:String;
		private var targetNearestChar:Boolean;
		
		private static const CHANCE_OF_RANDOM_FACE_CHANGE:Number = 0.25;
		private static const CHANCE_OF_CONTINUING_TO_FACE_TARGET:Number = 0.75;
		
		public function BrainFidget(entity:ComplexEntity, roomExplore:RoomExplore, param:String) {
			me = entity;
			if (param != "") {
				setTargetFromParam(param);
			}
			
			var facing:int = getFacingFunction();
			me.turnToFacing(facing, 0);
			// Set the first twitch opportunity to a random fraction of a second, so all the NPCs in
			// the room aren't acting in unison.
			roomExplore.addTimedEvent(Math.random(), twitchOpportunity);
		}
		
		public function cleanup():void {
			Assert.assertTrue(me.room.mode is RoomExplore, "Explore brain not in explore mode");
			RoomExplore(me.room.mode).removeTimedEvent(twitchOpportunity);
			me = null;
		}

		private function twitchOpportunity(roomExplore:RoomExplore):void {
			var currentFacing:int = me.currentFacing();
			var newFacing:int = getFacingFunction();
			if (currentFacing != newFacing) {
				me.turnToFacing(newFacing, 0);
				roomExplore.addTimedEvent(2, twitchOpportunity);
			} else {
				roomExplore.addTimedEvent(1, twitchOpportunity);
			}
		}
		
		private function setTargetFromParam(param:String):void {
			var splitParam:Array = param.split(":");
			if (splitParam.length == 1) {
				if (param == "nearest") {
					getFacingFunction = faceNearestChar;
				} else {
					entityTarget = param;
					getFacingFunction = faceTargetEntity;
				}
				return;
			}
			switch (splitParam[0]) {
				case "spot":
					spotTarget = me.room.spotLocation(splitParam[1]);
					if (spotTarget == null) {
						Alert.show("Error! Unknown spot " + splitParam[1]);
					} else {
						getFacingFunction = faceSpot;
					}
				break;
				case "char":
					entityTarget = splitParam[1];
					getFacingFunction = faceTargetEntity;
				break;
				default:
					Alert.show("Error! Unknown fidget param " + param);
				break;
			}
		}
		
		private function randomFacing():int {
			return (Math.random() < CHANCE_OF_RANDOM_FACE_CHANGE ? Math.random() * 8 : me.currentFacing());
		}
		
		private function mostlyFace(desiredFacing:int):int {
			if ((me.currentFacing() != desiredFacing) || Math.random() < CHANCE_OF_CONTINUING_TO_FACE_TARGET) {
				return desiredFacing;
			}
			return desiredFacing + ((Math.random() < 0.5) ? 1 : -1) ;
		}
		
		private function faceSpot():int {
			return mostlyFace(me.findFacingToTile(spotTarget));
		}
		
		private function faceTargetEntity():int {
			var entity:SimpleEntity = me.room.entityInRoomWithId(entityTarget);
			var desiredFacing:int = (entity == null ? me.currentFacing() : me.findFacingToTile(entity.location));
			return mostlyFace(desiredFacing);
		}
		
		private function faceNearestChar():int {
			var distance:int;
			var nearestDistance:int = int.MAX_VALUE;
			var nearestChar:ComplexEntity;
			me.room.forEachComplexEntity(function(entity:ComplexEntity):void {
				if (entity != me) {
					distance = Util.chessDistance(me.location, entity.location);
					if (distance < nearestDistance) {
						nearestDistance = distance;
						nearestChar = entity;
					}
				}
			} );
			var desiredFacing:int = (nearestChar == null ? me.currentFacing() : me.findFacingToTile(nearestChar.location));
			return mostlyFace(desiredFacing);
		}
		
	}

}