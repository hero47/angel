package angel.game {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.Defaults;
	import angel.game.combat.Grenade;

	
	public class Settings {
		
		public static var FRAMES_PER_SECOND:int;
		
		// These are set by the game engine so scripting can access them.
		// Is there a better way to do this sort of thing?
		// UNDONE: if this is legit, root out all the places I'm passing around catalog and use Settings.catalog instead
		// CONSIDER: should Catalog itself enforce being a singleton, and provide public static var catalog?
		public static var catalog:Catalog;
		public static var currentRoom:Room;
		
		public static var testExploreScroll:int;
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
		public static var grenadeDamage:int;
		
		public static var pcs:Vector.<ComplexEntity> = new Vector.<ComplexEntity>();
		
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
			setIntFromXml("grenadeDamage", Defaults.GRENADE_DAMAGE, xml.@grenadeDamage);
			
			setBooleanFromXml("showEnemyMoves", false, xml.@showEnemyMoves);
			setBooleanFromXml("controlEnemies", false, xml.@controlEnemies);
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
				var grenades:int = pc.@grenades;
				if (grenades > 0) {
					entity.inventory.add(Grenade.getCopy(), grenades);
				}
				pcs.push(entity);
			}
			
			
		}
		
	}

}