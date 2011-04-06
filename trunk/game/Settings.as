package angel.game {
	import angel.common.Alert;
	import angel.common.Catalog;

	
	public class Settings {
		
		public static const FRAMES_PER_SECOND:int = 30;
		public static const DEFAULT_MOVE_SPEED:Number = 2; // speeds in adjacent-tiles-per-second
		
		public static var testExploreScroll:int = 0;
		public static var showEnemyMoves:Boolean = false;
		public static var combatMovePoints:int = 10;
		public static var walkPoints:int;
		public static var runPoints:int;
		public static var sprintPoints:int;
		public static var baseDamage:int = 10;
		public static var minForOpportunity:int = 4;
		
		public static var exploreSpeed:Number = DEFAULT_MOVE_SPEED;
		public static var walkSpeed:Number = DEFAULT_MOVE_SPEED;
		public static var runSpeed:Number = DEFAULT_MOVE_SPEED;
		public static var sprintSpeed:Number = DEFAULT_MOVE_SPEED;
		
		public static var pcs:Vector.<ComplexEntity> = new Vector.<ComplexEntity>();
		
		public function Settings() {
			
		}
		
		public static function initFromXml(xml:XMLList):void {
			var temp:String;
			
			if (xml.@player.length() > 0 || xml.@playerHealth.length() > 0) {
				Alert.show("player or playerHealth found in 'Settings'.\nPlayer is now a separate entry in init file.\nSee Dev Notes!");
			}
			
			Settings.testExploreScroll = (xml.@testExploreScroll);
			if (xml.@combatMovePoints.length() > 0) {
				combatMovePoints = xml.@combatMovePoints;
			}
			
			// XML should contain settings for two of the three percents.  We want to set movement points for those
			// two speeds based on percent of total points, then give the third one whatever's left (so rounding
			// errors fall into the unspecified one).
			// Then, once that's figured out, convert them to totals.
			walkPoints = combatMovePoints * int(xml.@walkPercent)/100;
			runPoints = combatMovePoints * int(xml.@runPercent)/100;
			sprintPoints = combatMovePoints * int(xml.@sprintPercent) / 100;
			if (walkPoints + runPoints + sprintPoints == 0) {
				walkPoints = runPoints = combatMovePoints / 3;
			}
			if (walkPoints == 0) {
				walkPoints = combatMovePoints - runPoints - sprintPoints;
			}
			if (runPoints == 0) {
				runPoints = combatMovePoints - walkPoints - sprintPoints;
			}
			if (sprintPoints == 0) {
				sprintPoints = combatMovePoints - walkPoints - runPoints;
			}
			if (walkPoints + runPoints + sprintPoints != combatMovePoints) {
				Alert.show("Bad walk/run/sprint values in init");
			}
			runPoints += walkPoints;
			sprintPoints += runPoints;
			
			if (xml.@exploreSpeed.length() > 0) {
				exploreSpeed = xml.@exploreSpeed;
			}
			if (xml.@walkSpeed.length() > 0) {
				walkSpeed = xml.@walkSpeed;
			}
			if (xml.@runSpeed.length() > 0) {
				runSpeed = xml.@runSpeed;
			}
			if (xml.@sprintSpeed.length() > 0) {
				sprintSpeed = xml.@sprintSpeed;
			}
			if (xml.@baseDamage.length() > 0) {
				baseDamage = xml.@baseDamage;
			}
			if (xml.@minForOpportunity.length() > 0) {
				minForOpportunity = xml.@minForOpportunity;
			}
			
			showEnemyMoves = (String(xml.@showEnemyMoves) == "yes");
		}
		
		// This part will probably be going away or moving eventually -- identity of main PC and followers will be
		// script-controlled and stats will carry over from one scene to the next
		public static function initPlayerFromXml(xml:XMLList, catalog:Catalog):void {
			var entity:Walker;
			if (xml.length() == 0) {
				entity = new Walker(catalog.retrieveWalkerImage("PLAYER"), "PLAYER");
				entity.currentHealth = 100;
				pcs.push(entity);
				return;
			}
			
			var i:int = 1;
			for each (var pc:XML in xml.pc) {
				var id:String = pc.@id;
				if (id == "") {
					id = "PLAYER-" + i;
				}
				++i;
				entity = new Walker(catalog.retrieveWalkerImage(id), "PC-" + id);
				entity.exploreBrainClass = entity.combatBrainClass = null;
				if (pc.@health.length() > 0) {
					entity.maxHealth = entity.currentHealth = pc.@health;
				}
				pcs.push(entity);
			}
			
			
		}
		
	}

}