package angel.game.inventory {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.WeaponResource;
	import angel.game.combat.Grenade;
	import angel.game.combat.SingleTargetWeapon;
	import angel.game.Settings;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Inventory {
		
		public static const MAIN_HAND:int = 0;
		public static const OFF_HAND:int = 1;
		public static const NUMBER_OF_EQUIPPED_LOCATIONS:int = 2;
		
		private var equipmentSlots:Vector.<CanBeInInventory> = new Vector.<CanBeInInventory>(NUMBER_OF_EQUIPPED_LOCATIONS);
		//Everything that the character has that's not equipped is in the "pile of stuff"; we aren't tracking particular
		//location of carried objects (at least, not at this time)
		private var pileOfStuff:Dictionary; // mapping from CanBeInInventory to integer number of items
		
		public function Inventory() {
			pileOfStuff = new Dictionary();
		}
		
		public function mainWeapon():SingleTargetWeapon {
			return equipmentSlots[MAIN_HAND] as SingleTargetWeapon;
		}
		
		public function offWeapon():SingleTargetWeapon {
			return equipmentSlots[OFF_HAND] as SingleTargetWeapon;
		}
		
		public function hasFreeHand():Boolean {
			return ((equipmentSlots[MAIN_HAND] == null) || (equipmentSlots[OFF_HAND] == null));
		}
		
		public function itemInSlot(slot:int):CanBeInInventory {
			if (slot < 0 || slot >= NUMBER_OF_EQUIPPED_LOCATIONS) {
				return null;
			}
			return equipmentSlots[slot];
		}
		
		public static function isItemLegalInSlot(item:CanBeInInventory, slot:int):Boolean {
			switch (slot) {
				case MAIN_HAND:
				case OFF_HAND:
					return (item is SingleTargetWeapon);
				break;
			}
			return (item is CanBeInInventory);
		}
		
		//return true if successful
		public function equip(item:CanBeInInventory, slot:int, keepOld:Boolean):Boolean {
			if (!isItemLegalInSlot(item, slot)) {
				return false;
			}
			if (slot < 0 || slot >= NUMBER_OF_EQUIPPED_LOCATIONS) {
				addToPileOfStuff(item, 1);
				return true;
			}
			if (keepOld && (equipmentSlots[slot] != null)) {
				addToPileOfStuff(equipmentSlots[slot], 1);
			}
			equipmentSlots[slot] = item;
			return true;
		}
		
		public function equipFromPileOfStuff(item:CanBeInInventory, slot:int, keepOld:Boolean):Boolean {
			if (!isItemLegalInSlot(item, slot) || !removeFromPileOfStuff(item, 1)) {
				return false;
			}
			if (!equip(item, slot, keepOld)) {
				Assert.fail("Unable to equip legal item");
				addToPileOfStuff(item, 1);
				return false;
			}
			return true;
		}
		
		// move item from this slot back into general pile or throw it away
		public function unequip(slot:int, keep:Boolean):void {
			if ((slot >= 0) && (slot < NUMBER_OF_EQUIPPED_LOCATIONS) && (equipmentSlots[slot] != null)) {
				if (keep) {
					addToPileOfStuff(equipmentSlots[slot], 1);
				}
				equipmentSlots[slot] = null;
			}
		}
		
		public function everythingInPileOfStuff():Vector.<CanBeInInventory> {
			var pile:Vector.<CanBeInInventory> = new Vector.<CanBeInInventory>();
			for (var item:Object in pileOfStuff) {
				pile.push(item);
			}
			return pile;
		}
				
		// return new count
		public function addToPileOfStuff(item:CanBeInInventory, howMany:int = 1):int {
			if (howMany < 1) {
				Alert.show("Error! Adding " + howMany + " of something to inventory.");
				return howMany;
			}
			var count:int = int(pileOfStuff[item]) + howMany;
			pileOfStuff[item] = count;
			return count;
		}
		
		// return true if successful
		public function removeFromPileOfStuff(specificItem:CanBeInInventory, howMany:int):Boolean {
			var currentCount:int = pileOfStuff[specificItem];
			if (currentCount == 0) {
				return false;
			}
			if (currentCount <= howMany) {
				if (currentCount < howMany) {
					Alert.show("Error! Removing " + howMany + " items when inventory contains " + currentCount);
				}
				delete pileOfStuff[specificItem];
			} else {
				pileOfStuff[specificItem] = currentCount - howMany;
			}
			return true;
		}
		
		public function removeAllFromPileOfStuff(specificItem:CanBeInInventory):void {
			var currentCount:int = pileOfStuff[specificItem];
			if (currentCount == 0) {
				Alert.show("Error! Removing something that's not in inventory");
				return;
			}
			delete pileOfStuff[specificItem];
		}
		
		public function removeAllMatchingFromPileOfStuff(classToFind:Class):void {
			for (var item:Object in pileOfStuff) {
				if (item is classToFind) {
					delete pileOfStuff[item];
				}
			}
		}
		
		public function findFirstMatchingInPileOfStuff(classToFind:Class):* {
			for (var item:Object in pileOfStuff) {
				if (item is classToFind) {
					return CanBeInInventory(item);
				}
			}
			return null;
		}
		
		public function countSpecificItemInPileOfStuff(specificItem:Object):int {
			return pileOfStuff[specificItem];
		}
		
		public function countInPileOfStuff(classToFind:Class):int {
			var countInPileOfStuff:int = 0;
			for (var item:Object in pileOfStuff) {
				if (item is classToFind) {
					countInPileOfStuff += pileOfStuff[item];
				}
			}
			return countInPileOfStuff;
		}
		
		public function entriesInPileOfStuff():int {
			var count:int = 0;
			for (var item:Object in pileOfStuff) {
				count++;
			}
			return count;
		}
		
		public static function makeOne(id:String):CanBeInInventory {
			//NOTE: once we have more types of things that can be in inventory, this will need to retrieve
			//catalog entry, determine the appropriate resource type, and then create the item using that.
			//UNDONE: grenades don't have a weapon resource yet
			var item:CanBeInInventory;
			if (id == "grenade") {
				item = Grenade.getCopy();
			} else {
				var gunResource:WeaponResource = Settings.catalog.retrieveWeaponResource(id);
				item = new SingleTargetWeapon(gunResource, id);
			}
			return item;
		}
		
		public function addToPileFromText(text:String):void {
			var list:Array = text.split(",");
			for each (var entry:String in list) {
				var splitEntry:Array = entry.split(" ");
				var count:int = (splitEntry.length == 2) ? int(splitEntry[0]) : 1;
				var id:String = splitEntry[splitEntry.length - 1];
				var item:CanBeInInventory = Inventory.makeOne(id);
				if (item != null) {
					addToPileOfStuff(item, count);
				}
			}
		}
		
		public function debugListContents(header:String = null):void {
			if (header != null) {
				trace(header);
			}
			for (var item:Object in pileOfStuff) {
				trace(item, pileOfStuff[item]);
			}
			
		}
		
		// This is a placeholder for a much fancier inventory interface!
		public function showInventoryInAlert():void {
			var text:String = "Placeholder for inventory!\n\nCurrent inventory:";
			text += "\nMain hand: " + (equipmentSlots[MAIN_HAND] == null ? "[empty]" : equipmentSlots[MAIN_HAND].displayName);
			text += "\nOffhand: " + (equipmentSlots[OFF_HAND] == null ? "[empty]" : equipmentSlots[OFF_HAND].displayName);
			text += "\nUnequipped 'pile of stuff':";
			var countUnequipped:int = 0;
			for (var item:Object in pileOfStuff) {
				text += "\n  " + pileOfStuff[item] + " " + item.displayName;
				++countUnequipped;
			}
			if (countUnequipped == 0) {
				text += " [none]";
			}
			Alert.show(text);
		}
		
	}

}