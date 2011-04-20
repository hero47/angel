package angel.game {
	import angel.common.Alert;
	import angel.common.Catalog;

	
	public class Settings {
		
		public static const FRAMES_PER_SECOND:int = 30;
		public static const DEFAULT_MOVE_SPEED:Number = 2; // speeds in adjacent-tiles-per-second
		public static const DEFAULT_MOVE_POINTS:int = 10;
		
		public static var testExploreScroll:int = 0;
		public static var showEnemyMoves:Boolean = false;
		public static var walkPercent:int;
		public static var runPercent:int;
		public static var sprintPercent:int;
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
			
			if (xml.@combatMovePoints.length() > 0) {
				Alert.show("Warning: combatMovePoints found in 'Settings'.\nThis is no longer used; move points are set independently\nfor each character in character editor.");
			}
			
			Settings.testExploreScroll = (xml.@testExploreScroll);
			
			walkPercent = int(xml.@walkPercent);
			runPercent = int(xml.@runPercent);
			sprintPercent = int(xml.@sprintPercent);
			if (walkPercent != 0 && runPercent != 0 && sprintPercent != 0) {
				Alert.show("One of walk/run/sprintPercent should be 0 or omitted; that one gets the leftover points after rounding.");
			}
			
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