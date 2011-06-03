package angel.game.combat {
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import flash.display.DisplayObject;
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
		private static const ACTIONS_PREFIX:String = "Actions: ";
		
		private var displayName:TextField;
		private var health:TextField;
		private var movePoints:TextField;
		private var actionsRemaining:TextField;
		
		public function CombatStatDisplay() {
			displayName = createStatField(null, 100);
			displayName.x = 10;
			displayName.y = 5;
			addChild(displayName);
			
			health = createStatField(displayName, 100);
			movePoints = createStatField(health, 80);
			actionsRemaining = createStatField(movePoints, 80);
			
			movePoints.visible = false;
			actionsRemaining.visible = false;
		}
		
		private function createStatField(addBelow:DisplayObject, width:int):TextField {
			var myTextField:TextField = Util.textBox("", width, 20, TextFormatAlign.CENTER, false);
			myTextField.border = true;
			myTextField.background = true;
			if (addBelow != null) {
				Util.addBelow(myTextField, addBelow, 5);
			}
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
		
		public function adjustActionsRemainingDisplay(points:int):void {
			if (points >= 0) {
				actionsRemaining.visible = true;
				actionsRemaining.text = ACTIONS_PREFIX + String(points);
			} else {
				actionsRemaining.visible = false;
			}
		}
	}

}