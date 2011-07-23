package angel.game.combat {
	import angel.common.Assert;
	import angel.common.Util;
	import angel.common.WeaponResource;
	import angel.game.ComplexEntity;
	import angel.game.Icon;
	import angel.game.inventory.CanBeInInventory;
	import angel.game.Settings;
	import angel.game.TimedSprite;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.geom.Point;
	import flash.text.TextField;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	 // This may become an interface once we have more types of guns, or the others may extend it
	public class SingleTargetWeapon extends WeaponBase implements IHandWeapon {
		public var range:int;
		public var cooldown:int;
		private var combatTurnLastFired:int = -99;
		public var ignoreUserGait:Boolean;
		public var ignoreTargetGait:Boolean;
		
		public function SingleTargetWeapon(resource:WeaponResource, id:String) {
			super(resource, id);
			this.range = resource.range;
			this.cooldown = resource.cooldown;
			this.ignoreUserGait = resource.ignoreUserGait;
			this.ignoreTargetGait = resource.ignoreTargetGait;
		}
		
		public function toString():String {
			return "[SingleTargetWeapon displayName=" + name + ", baseDamage=" + baseDamage + "]";
		}
		
		public function stacksWith(other:CanBeInInventory):Boolean {
			var otherWeapon:SingleTargetWeapon = other as SingleTargetWeapon;
			return ((otherWeapon != null) && (otherWeapon.id == id) && (otherWeapon.combatTurnLastFired == combatTurnLastFired));
		}
		
		override public function clone():CanBeInInventory {
			var copy:SingleTargetWeapon = SingleTargetWeapon(super.clone());
			copy.combatTurnLastFired = this.combatTurnLastFired;
			return copy;
		}
		
		public function useOn(user:ComplexEntity, target:Object):void {
			if (target is ComplexEntity) {
				fire(user, ComplexEntity(target));
			} else {
				Assert.fail("Bad target type " + target + " in " + this);
			}
		}
		
		public function inRange(shooter:ComplexEntity, targetLocation:Point):Boolean {
			return (Util.chessDistance(shooter.location, targetLocation) <= range);
		}
		
		public function readyToFire(combat:RoomCombat):Boolean {
			if (combat == null) {
				return true;
			}
			return (combatTurnLastFired + cooldown <= combat.combatTurn);
		}
		
		// Used to set all ready-to-fire weapons to the same cooldown so they'll stack in inventory
		public function standardizeCooldown(combat:RoomCombat):void {
			if (readyToFire(combat)) {
				combatTurnLastFired = -99;
			}
		}
		
		//NOTE: "fire" is currently the generic term for "attack target" even if the weapon happens to be melee
		public function fire(shooter:ComplexEntity, target:ComplexEntity, coverDamageReductionPercent:int = 0):void {
			var combat:RoomCombat = RoomCombat(shooter.room.mode);
			shooter.turnToFaceTile(target.location);
			--shooter.actionsRemaining;
			
			if (!readyToFire(combat) || !inRange(shooter, target.location)) {
				Assert.fail("Trying to fire weapon illegally");
				return;
			}
			
			combatTurnLastFired = combat.combatTurn;
			var damage:int = baseDamage;
			if (shooter.inventory.offWeapon() != null) {
				damage *= ((this == shooter.inventory.mainWeapon()) ? Settings.DUAL_WIELD_PERCENT : Settings.OFF_WIELD_PERCENT) / 100;
			}
			if (!ignoreUserGait) {
				damage *= shooter.damageDealtSpeedPercent() / 100;
			}
			target.takeDamage(damage, !ignoreTargetGait, coverDamageReductionPercent);
			
			if (shooter.isPlayerControlled || target.isPlayerControlled ||
							combat.anyPlayerCanSeeLocation(target.location) ||
							combat.anyPlayerCanSeeLocation(shooter.location) ) {				
				var uglyFireLineThatViolates3D:TimedSprite = new TimedSprite(Settings.FRAMES_PER_SECOND);
				uglyFireLineThatViolates3D.graphics.lineStyle(2, (shooter.isPlayerControlled ? 0xff0000 : 0xffa500));
				uglyFireLineThatViolates3D.graphics.moveTo(shooter.centerOfImage().x, shooter.centerOfImage().y);
				uglyFireLineThatViolates3D.graphics.lineTo(target.centerOfImage().x, target.centerOfImage().y);
				shooter.room.addChild(uglyFireLineThatViolates3D);
			}
			
			if (target.isPlayerControlled) {
				target.centerRoomOnMe();
			}
		}
		
		public function expectedDamage(shooter:ComplexEntity, target:ComplexEntity):int {
			return baseDamage * shooter.damageDealtSpeedPercent() / 100 * target.damageTakenSpeedPercent() / 100;
		}
		
	}

}