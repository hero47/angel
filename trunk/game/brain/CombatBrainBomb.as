package angel.game.brain {
	import angel.common.Defaults;
	import angel.game.combat.RoomCombat;
	import angel.game.combat.ThrownWeapon;
	import angel.game.combat.TimeDelayGrenade;
	import angel.game.ComplexEntity;
	import angel.game.Room;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Sit there doing nothing for some number of turns, then explode.
	// Parameter is damage:turns
	public class CombatBrainBomb extends CombatBrainUiMeld {
		private var damage:int = 0;
		private var turnsLeft:int = 1;
		
		public function CombatBrainBomb(entity:ComplexEntity, combat:RoomCombat, param:String) {
			super(entity, combat);
			if ((param != null) && (param != "")) {
				var splitParam:Array = param.split(":");
				damage = int(splitParam[0]);
				if (splitParam.length > 1) {
					turnsLeft = int(splitParam[1]);
				}
			}
			entity.controllingOwnText = true;
			entity.setTextOverHead(String(turnsLeft), TimeDelayGrenade.COUNTDOWN_COLOR);
		}
		
		/* INTERFACE angel.game.brain.ICombatBrain */
		
		override public function doFire():void {
			if (--turnsLeft < 1) {
				var room:Room = me.room;
				var location:Point = me.location;
				room.removeEntity(me);
				ThrownWeapon.explodeAt(room, location, damage);
			} else {
				me.setTextOverHead(String(turnsLeft), TimeDelayGrenade.COUNTDOWN_COLOR);
				useCombatItemOnTarget(null, null);
			}
		}
		
	}
}
