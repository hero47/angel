package angel.game.combat {
	import angel.game.ComplexEntity;
	import angel.game.Settings;
	import angel.game.TimedSprite;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	 // This may become an interface once we have more types of guns, or the others may extend it
	public class Gun {
		public var baseDamage:int;
		
		public function Gun(baseDamage:int) {
			this.baseDamage = baseDamage;
		}
		
		public function fire(shooter:ComplexEntity, target:ComplexEntity, extraDamageReductionPercent:int = 0):void {
			shooter.turnToFaceTile(target.location);
			--shooter.actionsRemaining;
			
			target.takeDamage(baseDamage * shooter.percentOfFullDamageDealt() / 100, true, extraDamageReductionPercent);
			
			var uglyFireLineThatViolates3D:TimedSprite = new TimedSprite(Settings.FRAMES_PER_SECOND);
			uglyFireLineThatViolates3D.graphics.lineStyle(2, (shooter.isPlayerControlled ? 0xff0000 : 0xffa500));
			uglyFireLineThatViolates3D.graphics.moveTo(shooter.center().x, shooter.center().y);
			uglyFireLineThatViolates3D.graphics.lineTo(target.center().x, target.center().y);
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