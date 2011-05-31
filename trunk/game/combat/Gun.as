package angel.game.combat {
	import angel.common.WeaponResource;
	import angel.game.CanBeInInventory;
	import angel.game.ComplexEntity;
	import angel.game.Settings;
	import angel.game.TimedSprite;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	 // This may become an interface once we have more types of guns, or the others may extend it
	public class Gun implements IWeapon {
		private var id:String;
		public var name:String;
		public var baseDamage:int;
		
		public function Gun(resource:WeaponResource, id:String) {
			this.id = id;
			this.baseDamage = resource.damage;
			this.name = resource.displayName;
		}
		
		public function toString():String {
			return "[Gun displayName=" + name + ", baseDamage=" + baseDamage + "]";
		}
		
		public function get displayName():String {
			return name;
		}
		
		public function fire(shooter:ComplexEntity, target:ComplexEntity, extraDamageReductionPercent:int = 0):void {
			shooter.turnToFaceTile(target.location);
			--shooter.actionsRemaining;
			
			target.takeDamage(baseDamage * shooter.percentOfFullDamageDealt() / 100, true, extraDamageReductionPercent);
			
			var uglyFireLineThatViolates3D:TimedSprite = new TimedSprite(Settings.FRAMES_PER_SECOND);
			uglyFireLineThatViolates3D.graphics.lineStyle(2, (shooter.isPlayerControlled ? 0xff0000 : 0xffa500));
			uglyFireLineThatViolates3D.graphics.moveTo(shooter.centerOfImage().x, shooter.centerOfImage().y);
			uglyFireLineThatViolates3D.graphics.lineTo(target.centerOfImage().x, target.centerOfImage().y);
			shooter.room.addChild(uglyFireLineThatViolates3D);
			
			if (!shooter.isPlayerControlled) {
				target.centerRoomOnMe();
			}
		}
		
		public function expectedDamage(shooter:ComplexEntity, target:ComplexEntity):int {
			return baseDamage * shooter.percentOfFullDamageDealt() / 100 * target.damagePercentAfterSpeedApplied() / 100;
		}
		
	}

}