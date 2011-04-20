package angel.game {
	import angel.common.Util;
	import flash.display.Sprite;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// Stuff that Wm wants shown in the corner of the screen for active player
	// Currently just a catch-all because Wm refuses to make it a pane rather than a bunch of random boxes
	public class CombatStatDisplay extends Sprite {
		
		private static const PLAYER_HEALTH_PREFIX:String = "Health: ";
		private static const MOVE_POINTS_PREFIX:String = "Move: ";
		
		private var displayName:TextField;
		private var health:TextField;
		private var movePoints:TextField;
		
		public function CombatStatDisplay() {
			var leftAlign:int = 10;
			var nextY:int = 5;
			
			displayName = createNameTextField();
			displayName.x = leftAlign;
			displayName.y = nextY;
			nextY += 25;
			addChild(displayName);
			
			health = createHealthTextField();
			health.x = leftAlign;
			health.y = nextY;
			nextY += 25;
			addChild(health);
			
			movePoints = createMovePointsTextField();
			movePoints.x = leftAlign;
			movePoints.y = nextY;
			nextY += 25;
			addChild(movePoints);
		}
		
		
		public static function createHealthTextField():TextField {
			var myTextField:TextField = Util.textBox("", 100, 20, TextFormatAlign.CENTER, false);
			myTextField.border = true;
			myTextField.background = true;
			return myTextField;
		}
		
		private function createNameTextField():TextField {
			var myTextField:TextField = Util.textBox("", 100, 20, TextFormatAlign.CENTER, false);
			myTextField.border = true;
			myTextField.background = true;
			return myTextField;
		}
		
		private function createMovePointsTextField():TextField {
			var myTextField:TextField = Util.textBox("", 80, 20, TextFormatAlign.CENTER, false);
			myTextField.border = true;
			myTextField.background = true;
			return myTextField;
		}
		
		public function adjustCombatStatDisplay(entity:ComplexEntity):void {
			if (entity == null) {
				visible = false;
			} else {
				visible = true;
				displayName.text = entity.displayName;
				health.text = PLAYER_HEALTH_PREFIX + String(entity.currentHealth);
			}
		}
		
		public function adjustMovePointsDisplay(points:int):void {
			if (points >= 0) {
				movePoints.visible = true;
				movePoints.text = MOVE_POINTS_PREFIX + String(points);
			} else {
				movePoints.visible = false;
			}
		}
	}

}