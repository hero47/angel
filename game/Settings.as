package angel.game {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.Defaults;
	import angel.game.event.EventQueue;
	import angel.game.script.Script;
	import angel.game.script.TriggerMaster;

	
	public class Settings {
		
		public static var FRAMES_PER_SECOND:int;
		public static var STAGE_HEIGHT:int;
		public static var STAGE_WIDTH:int;
		
		// These are potentially needed everywhere in the code, so I'm effectively making them global.
		// Discuss this with Mickey.
		// UNDONE: if this is legit, root out all the places I'm passing around catalog and use Settings.catalog instead
		// CONSIDER: should Catalog itself enforce being a singleton, and provide public static var catalog?
		public static var catalog:Catalog;
		public static var triggerMaster:TriggerMaster;
		public static var gameEventQueue:EventQueue;
		
		// "Constants" initialized from the game settings file.
		// These are treated as if they were static constants.  Some of them may become static constants
		// later; they're variables to allow Wm to experiment with different settings, but we may decide
		// that they shouldn't vary.  Some of them will be removed and the corresponding code stripped out
		// once Wm makes a decision (because we don't want the clutter and expense of maintaining code for
		// options that we've decided not to make use of).  Some of them will probably remain variables
		// even after the game is released.
		public static var testExploreScroll:int;
		public static var mouseScroll:int;
		public static var showEnemyMoves:Boolean;
		public static var walkPercent:int;
		public static var runPercent:int;
		public static var sprintPercent:int;
		public static var minForOpportunity:int;
		
		public static var controlEnemies:Boolean;
		
		public static var exploreSpeed:Number;
		public static var walkSpeed:Number;
		public static var runSpeed:Number;
		public static var sprintSpeed:Number;
		
		public static var penaltyWalk:int;
		public static var penaltyRun:int;
		public static var penaltySprint:int;
		public static var defenseWalk:int;
		public static var defenseRun:int;
		public static var defenseSprint:int;
		public static var speedPenalties:Vector.<int>;
		public static var speedDefenses:Vector.<int>;
		public static var fireFromCoverDamageReduction:int;
		
		public static var saveDataForNewGame:SaveGame;
		public static var startScript:Script;
		
		public function Settings() {
			
		}
		
		public static function initFromXml(xml:XMLList):void {
			if (xml.@combatMovePoints.length() > 0) {
				Alert.show("Warning: combatMovePoints found in 'Settings'.\nThis is no longer used; move points are set independently\nfor each character in character editor.");
			}
			
			if (xml.@baseDamage.length() > 0) {
				Alert.show("Warning: baseDamage found in 'Settings'.\nThis is no longer used; weapon damage is set independently\nfor each character in character editor.");
			}
			
			Settings.testExploreScroll = (xml.@testExploreScroll);
			Settings.mouseScroll = (xml.@mouseScroll);
			
			walkPercent = int(xml.@walkPercent);
			runPercent = int(xml.@runPercent);
			sprintPercent = int(xml.@sprintPercent);
			if (walkPercent != 0 && runPercent != 0 && sprintPercent != 0) {
				Alert.show("One of walk/run/sprintPercent should be 0 or omitted; that one gets the leftover points after rounding.");
			}
			
			setNumberFromXml("exploreSpeed", Defaults.MOVE_SPEED, xml.@exploreSpeed);
			setNumberFromXml("walkSpeed", Defaults.MOVE_SPEED, xml.@walkSpeed);
			setNumberFromXml("runSpeed", Defaults.MOVE_SPEED, xml.@runSpeed);
			setNumberFromXml("sprintSpeed", Defaults.MOVE_SPEED, xml.@sprintSpeed);
			setIntFromXml("penaltyWalk", Defaults.PENALTY_WALK, xml.@penaltyWalk);
			setIntFromXml("penaltyRun", Defaults.PENALTY_RUN, xml.@penaltyRun);
			setIntFromXml("penaltySprint", Defaults.PENALTY_SPRINT, xml.@penaltySprint);
			speedPenalties = Vector.<int>([0, penaltyWalk, penaltyRun, penaltySprint]);
			setIntFromXml("defenseWalk", Defaults.DEFENSE_WALK, xml.@defenseWalk);
			setIntFromXml("defenseRun", Defaults.DEFENSE_RUN, xml.@defenseRun);
			setIntFromXml("defenseSprint", Defaults.DEFENSE_SPRINT, xml.@defenseSprint);
			speedDefenses = Vector.<int>([0, defenseWalk, defenseRun, defenseSprint]);
			setIntFromXml("fireFromCoverDamageReduction", Defaults.FIRE_FROM_COVER_DAMAGE_REDUCTION, xml.@fireFromCoverDamageReduction);
			setIntFromXml("minForOpportunity", Defaults.MIN_FOR_OPPORTUNITY, xml.@minForOpportunity);
			
			setBooleanFromXml("showEnemyMoves", false, xml.@showEnemyMoves);
			setBooleanFromXml("controlEnemies", false, xml.@controlEnemies);
		}
		
		public static function initStartScript(xml:XML):void {
			if (xml.length() > 0) {
				startScript = new Script(xml);
			}
		}
		
		private static function setIntFromXml(propertyName:String, defaultValue:int, xmlValue:String):void {
			Settings[propertyName] = (xmlValue == "" ? defaultValue : int(xmlValue));
		}
		
		private static function setNumberFromXml(propertyName:String, defaultValue:Number, xmlValue:String):void {
			Settings[propertyName] = (xmlValue == "" ? defaultValue : Number(xmlValue));
		}
		
		private static function setStringFromXml(propertyName:String, defaultValue:String, xmlValue:String):void {
			Settings[propertyName] = (xmlValue == "" ? defaultValue : xmlValue);
		}
		
		private static function setBooleanFromXml(propertyName:String, defaultValue:Boolean, xmlValue:String):void {
			Settings[propertyName] = (defaultValue ? xmlValue != "no" : xmlValue == "yes");
		}
		
	} // end class Settings

}