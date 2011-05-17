package angel.game.brain {
	import angel.common.Alert;
	import angel.common.Util;
	import angel.game.combat.Gun;
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

		private static const exploreBrain:Object = { fidget:BrainFidget, follow:BrainFollow, patrol:BrainPatrol, wander:BrainWander };
		private static const combatBrain:Object = { patrol:CombatBrainPatrol, patrolNoStops:CombatBrainPatrolNoStops,
		wander:CombatBrainWander };

		public static function exploreBrainClassFromString(brainName:String):Class {
			if ((brainName == null) || (brainName == "")) {
				return null;
			}
			return exploreBrain[brainName];
		}

		public static function combatBrainClassFromString(brainName:String):Class {
			if ((brainName == null) || (brainName == "")) {
				return null;
			}
			return combatBrain[brainName];
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
		
		public static function canShoot(me:ComplexEntity,  combat:RoomCombat):Boolean {
			return (me.inventory.findA(Gun) != null) && (UtilBrain.getFirstAvailableTarget(me, combat) != null);
		}
		
	}

}