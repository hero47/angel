package angel.game.combat {
	import angel.common.Assert;
	import angel.common.Util;
	import angel.common.WeaponResource;
	import angel.game.CanBeInInventory;
	import angel.game.ComplexEntity;
	import angel.game.Settings;
	import angel.game.TimedSprite;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	 // This may become an interface once we have more types of guns, or the others may extend it
	public class SingleTargetWeapon implements IWeapon {
		private var id:String;
		public var name:String;
		public var baseDamage:int;
		public var range:int;
		public var cooldown:int;
		public var turnsSinceLastFired:int;
		
		public function SingleTargetWeapon(resource:WeaponResource, id:String) {
			this.id = id;
			this.baseDamage = resource.damage;
			this.name = resource.displayName;
			this.range = resource.range;
			this.cooldown = resource.cooldown;
			resetCooldown();
		}
		
		public function toString():String {
			return "[SingleTargetWeapon displayName=" + name + ", baseDamage=" + baseDamage + "]";
		}
		
		public function get displayName():String {
			return name;
		}
		
		public function attack(user:ComplexEntity, target:Object):void {
			fire(user, ComplexEntity(target));
		}
		
		public function inRange(shooter:ComplexEntity, targetLocation:Point):Boolean {
			return (Util.chessDistance(shooter.location, targetLocation) <= range);
		}
		
		public function readyToFire():Boolean {
			return (turnsSinceLastFired >= cooldown);
		}
		
		public function doCooldown():void {
			++turnsSinceLastFired;
		}
		
		public function resetCooldown():void {
			turnsSinceLastFired = cooldown;
		}
		
		//NOTE: "fire" is currently the generic term for "attack target" even if the weapon happens to be melee
		public function fire(shooter:ComplexEntity, target:ComplexEntity, extraDamageReductionPercent:int = 0):void {
			shooter.turnToFaceTile(target.location);
			--shooter.actionsRemaining;
			
			if (!readyToFire() || !inRange(shooter, target.location)) {
				Assert.fail("Trying to fire weapon illegally");
				return;
			}
			
			turnsSinceLastFired = 0;
			target.takeDamage(baseDamage * shooter.percentOfFullDamageDealt() / 100, true, extraDamageReductionPercent);
			
			var uglyFireLineThatViolates3D:TimedSprite = new TimedSprite(Settings.FRAMES_PER_SECOND);
			uglyFireLineThatViolates3D.graphics.lineStyle(2, (shooter.isPlayerControlled ? 0xff0000 : 0xffa500));
			uglyFireLineThatViolates3D.graphics.moveTo(shooter.centerOfImage().x, shooter.centerOfImage().y);
			uglyFireLineThatViolates3D.graphics.lineTo(target.centerOfImage().x, target.centerOfImage().y);
			shooter.room.addChild(uglyFireLineThatViolates3D);
			
			if (target.isPlayerControlled) {
				target.centerRoomOnMe();
			}
		}
		
		public function expectedDamage(shooter:ComplexEntity, target:ComplexEntity):int {
			return baseDamage * shooter.percentOfFullDamageDealt() / 100 * target.damagePercentAfterSpeedApplied() / 100;
		}
		
	}

}