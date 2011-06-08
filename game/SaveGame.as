package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.Catalog;
	import angel.common.RoomContentResource;
	import angel.game.brain.BrainFollow;
	import angel.game.brain.CombatBrainUiMeldPlayer;
	import angel.game.inventory.Inventory;
	import flash.geom.Point;
	import flash.net.SharedObject;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class SaveGame {
		
		// This is currently initialized from game settings file, but will eventually be part of the "game state",
		// initialized from game settings the first time the game is started and from a saved game any time the
		// game is reloaded.  Player inventory, current room, flag settings, etc. belong to the same category.
		private var pcs:Vector.<ComplexEntity> = new Vector.<ComplexEntity>();
		
		public var startRoomFile:String;
		public var startLocation:Point;
		public var startSpot:String;
		private var pcInitXml:Vector.<XML>;
		
		public function SaveGame() {
		}
		
		public static function save(text:String):void {
			try {
				var shared:SharedObject = SharedObject.getLocal("MaelstromAngelSave");
			} catch (error:Error) {
				Alert.show("Error! Unable to access Flash SharedObject for save game.");
				return;
			}
			shared.data.save1 = text;
			shared.flush();
			shared.close();
		}
		
		public static function load():String {
			try {
				var shared:SharedObject = SharedObject.getLocal("MaelstromAngelSave");
			} catch (error:Error) {
				Alert.show("Error! Unable to access Flash SharedObject for save game.");
				return null;
			}
			var text:String = shared.data.save1;
			shared.close();
			return text;
		}
		
		/***************************************************************/
		
		public function initStartRoomFromXml(xml:XMLList):void {
			if (xml.length() > 0) {
				startSpot = xml[0].@start;
				startRoomFile = xml[0].@file;
			}
			if (startRoomFile == "") {
				Alert.show("Error! Init file must include room to start in.");
			}
		}
		
		public function initPlayerInfoFromXml(playersXmlList:XMLList, catalog:Catalog):void {
			pcInitXml = new Vector.<XML>();
			if (playersXmlList.length() == 0) {
				pcInitXml.push(<pcXml id="PLAYER" health="100" />);
				return;
			}
			var i:int = 1;
			var previousPcId:String = null;
			for each (var pcXml:XML in playersXmlList.pc) {
				var id:String = pcXml.@id;
				if (id == "") {
					id = "PLAYER-" + i;
					pcXml.@id = id;
				}
				++i;
				
				if (playersXmlList.@inv.length() == 0) {
					convertXmlInventoryToInv(id, pcXml);
				}
				
				pcInitXml.push(pcXml);
			}
		}
		
		// Currently the init file uses a spread-out xml notation for inventory; pcs are initialized to the default
		// inventory for that character id as set in the Editor, then each piece of info from the init file, if present,
		// overrides the defaults for that slot/pile.  We may change this in the future to just store the inv text string;
		// if so, this function will no longer be needed.
		private function convertXmlInventoryToInv(id:String, xml:XML):void {
			var inventory:Inventory;
			var resource:RoomContentResource = Settings.catalog.retrieveCharacterResource(id);
			if (resource == null) {
				inventory = new Inventory();
			} else {
				var entity:ComplexEntity = new ComplexEntity(resource, id);
				inventory = entity.inventory.clone();
				entity.cleanup();
			}
			
			if (xml.@mainGun.length() > 0) {
				inventory.equip(Inventory.makeOne(xml.@mainGun), Inventory.MAIN_HAND, false);
				delete xml.@mainGun;
			}
			if (xml.@offGun.length() > 0) {
				inventory.equip(Inventory.makeOne(xml.@offGun), Inventory.OFF_HAND, false);
				delete xml.@offGun;
			}
			if (xml.@inventory.length() > 0) {
				inventory.removeAllMatchingFromPileOfStuff(Object);
				inventory.addToPileFromText(xml.@inventory);
				delete xml.@inventory;
			}
			
			//UNDONE: get rid of this once files are converted
			if (xml.@grenades.length() > 0) {
				var grenades:int = xml.@grenades;
				if (grenades > 0) {
					inventory.addToPileOfStuff(Inventory.makeOne("grenade"), grenades);
				}
				delete xml.@grenades;
			}
			
			xml.@inv = inventory.toText();
		}
		
		private function playerEntityFromInit(initXml:XML):ComplexEntity {
			var resource:RoomContentResource = Settings.catalog.retrieveCharacterResource(initXml.@id);
			if (resource == null) {
				return null;
			}
			var entity:ComplexEntity = new ComplexEntity(resource, initXml.@id);
			entity.faction = ComplexEntity.FACTION_FRIEND;
			entity.exploreBrainClass = null;
			entity.combatBrainClass = CombatBrainUiMeldPlayer;
			entity.inventory = Inventory.fromText(initXml.@inv);
			if (initXml.@health.length() > 0) {
				entity.maxHealth = entity.currentHealth = initXml.@health;
			}
			return entity;
		}
		
		public function addPlayerCharactersToRoom(room:Room):void {
			if (startLocation == null) {
				if ((startSpot == null) || (startSpot == "")) {
					startSpot = "start";
				}
				startLocation = room.spotLocationWithDefault(startSpot);
			}
			
			room.snapToCenter(startLocation);
			
			for (var i:int = 0; i < pcInitXml.length; ++i) {
				var player:ComplexEntity = playerEntityFromInit(pcInitXml[i]);
				if (player != null) {
					if (i > 0) {
						player.exploreBrainClass = BrainFollow;
						player.exploreBrainParam = pcInitXml[i - 1].@id;
					}
					// CONSIDER: start followers near main PC instead of stacked on the same square?
					// Though, as Wm pointed out, this actually makes sense when they're conceptually entering room through a door.
					room.addPlayerCharacter(player, startLocation);
				}
			}
		}
		
		public function collectRoomInfo(room:Room):void {
			startRoomFile = room.filename;
			startLocation = room.mainPlayerCharacter.location;
			pcInitXml = new Vector.<XML>();
			room.forEachComplexEntity(collectPlayerInfo);
		}
		
		private function collectPlayerInfo(entity:ComplexEntity):void {
			if (!entity.isReallyPlayer) {
				return;
			}
			var xml:XML = <pc />
			xml.@id = entity.id;
			xml.@health = entity.maxHealth;
			xml.@inv = entity.inventory.toText();
			pcInitXml.push(xml);
		}
		
	}

}