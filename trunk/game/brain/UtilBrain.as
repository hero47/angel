package angel.game.brain {
	import angel.common.Alert;
	import angel.common.Util;
	import angel.game.combat.RoomCombat;
	import angel.game.ComplexEntity;
	import angel.game.Room;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class UtilBrain {
		
		public function UtilBrain() {
			
		}
		
		public static function pointsFromCommaSeparatedSpots(room:Room, spots:String, errorMessageTail:String = ""):Vector.<Point> {
			var points:Vector.<Point> = new Vector.<Point>();
			var spotArray:Array = spots.split(",");
			for (var i:int = 0; i < spotArray.length; ++i) {
				var spotLocation:Point = room.spotLocation(spotArray[i]);
				if (spotLocation == null) {
					Alert.show("Error! Unknown spot " + spotArray[i] + errorMessageTail);
				} else {
					points.push(spotLocation);
				}
			}
			return points;
		}
		
		public static function fireAtFirstAvailableTarget(me:ComplexEntity, combat:RoomCombat):void {
			combat.fireAndAdvanceToNextPhase(me, getFirstAvailableTarget(me, combat));
		}
		
		public static function getFirstAvailableTarget(me:ComplexEntity, combat:RoomCombat):ComplexEntity {
			for (var i:int = 0; i < combat.fighters.length; i++) {
				var fighter:ComplexEntity = combat.fighters[i];
				if (fighter.isPlayerControlled && Util.entityHasLineOfSight(me, fighter.location)) {
					return fighter;
				}
			}
			return null;
		}
		
	}

}