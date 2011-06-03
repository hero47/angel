package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.CatalogEntry;
	import angel.common.Defaults;
	import angel.common.RoomContentResource;
	import angel.common.WeaponResource;
	import angel.game.brain.BrainFollow;
	import angel.game.brain.CombatBrainUiMeldPlayer;
	import angel.game.combat.Grenade;
	import angel.game.combat.SingleTargetWeapon;
	import angel.game.event.EventQueue;

	
	public class Settings {
		
		public static var FRAMES_PER_SECOND:int;
		public static var STAGE_HEIGHT:int;
		public static var STAGE_WIDTH:int;
		
		// These are potentially needed everywhere in the code, so I'm effectively making them global.
		// Discuss this with Mickey.
		// UNDONE: if this is legit, root out all the places I'm passing around catalog and use Settings.catalog instead
		// CONSIDER: should Catalog itself enforce being a singleton, and provide public static var catalog?
		public static var catalog:Catalog;
		public static var gameEventQueue:EventQueue;
		
		// "Constants" initialized from the game settings file.
		// These are treated as if they were static constants.  Some of them may become static constants
		// later; they're variables to allow Wm to experiment with different settings, but we may decide
		// that they shouldn't vary.  Some of them will be removed and the corresponding code stripped out
		// once Wm makes a decision (because we don't want the clutter and expense of maintaining code for
		// options that we've decided not to make use of).  Some of them will probably remain variables
		// even after the game is released.
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
		
		// This is currently initialized from game settings file, but will eventually be part of the "game state",
		// initialized from game settings the first time the game is started and from a saved game any time the
		// game is reloaded.  Player inventory, current room, flag settings, etc. belong to the same category.
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
		public static function initPlayersFromXml(xml:XMLList, catalog:Catalog):void {
			var entity:ComplexEntity;
			if (xml.length() == 0) {
				entity = new ComplexEntity(catalog.retrieveCharacterResource("PLAYER"), "PLAYER");
				entity.currentHealth = 100;
				entity.faction = ComplexEntity.FACTION_FRIEND;
				pcs.push(entity);
				return;
			}
			
			var i:int = 1;
			var previousPcId:String = null;
			for each (var pc:XML in xml.pc) {
				var id:String = pc.@id;
				if (id == "") {
					id = "PLAYER-" + i;
				}
				++i;
				var resource:RoomContentResource = catalog.retrieveCharacterResource(id);
				if (resource == null) {
					continue;
				}
				entity = new ComplexEntity(resource, id);
				entity.faction = ComplexEntity.FACTION_FRIEND;
				entity.exploreBrainClass = null;
				entity.combatBrainClass = CombatBrainUiMeldPlayer;
				if (pc.@health.length() > 0) {
					entity.maxHealth = entity.currentHealth = pc.@health;
				}
				
				if (pc.@mainGun.length() > 0) {
					entity.inventory.removeAllMatching(SingleTargetWeapon);
					var gunResource:WeaponResource = Settings.catalog.retrieveWeaponResource(pc.@mainGun);
					entity.inventory.add(new SingleTargetWeapon(gunResource, pc.@mainGun));
				}
				
				if (pc.@grenades.length() > 0) {
					entity.inventory.removeAllMatching(Grenade);
					var grenades:int = pc.@grenades;
					if (grenades > 0) {
						entity.inventory.add(Grenade.getCopy(), grenades);
					}
				}
				
				if (previousPcId != null) {
					entity.exploreBrainClass = BrainFollow;
					entity.exploreBrainParam = previousPcId;
				}
				previousPcId = entity.id;
				
				pcs.push(entity);
			}
		}
		
		public static function addToPlayerList(entity:ComplexEntity):void {
			if (pcs.indexOf(entity) < 0) {
				pcs.push(entity);
			} else {
				Assert.fail("addToPlayerList: entity already in list");
			}
		}
		
		public static function removeFromPlayerList(entity:SimpleEntity):void {
			var index:int = pcs.indexOf(entity);
			Assert.assertTrue(index >= 0, "removePc not in list");
			pcs.splice(index, 1);
		}
		
		public static function isOnPlayerList(entity:SimpleEntity):Boolean {
			return (pcs.indexOf(entity) >= 0);
		}
		
		// return true if succeeded, false if it wasn't on the list to begin with
		public static function moveToFrontOfPlayerList(entity:SimpleEntity):Boolean {
			var index:int = pcs.indexOf(entity);
			if (index < 0) {
				return false;
			}
			pcs.splice(index, 1);
			pcs.splice(0, 0, entity);
			return true;
		}
		
		public static function lastEntityOnPlayerList():ComplexEntity {
			return pcs[pcs.length - 1];
		}
		
	} // end class Settings

}