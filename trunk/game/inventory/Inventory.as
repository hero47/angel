package angel.game.inventory {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.MessageCollector;
	import angel.common.Util;
	import angel.game.combat.SingleTargetWeapon;
	import angel.game.Settings;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	//NOTE: currently inventory is not an ICleanup() -- it's just a toss-and-forget.  If inventory items ever start needing
	//cleanup, then Inventory will need to have a cleanup() function which does that for all its contents, and places that
	//make use of Inventory will need to call it.
	public class Inventory {
		
		public static const MAIN_HAND:int = 0;
		public static const OFF_HAND:int = 1;
		public static const NUMBER_OF_EQUIPPED_LOCATIONS:int = 2;
		
		private var equipmentSlots:Vector.<CanBeInInventory> = new Vector.<CanBeInInventory>(NUMBER_OF_EQUIPPED_LOCATIONS);

		private var pileOfStuff:Dictionary; // mapping from CanBeInInventory to integer number of items
		
		public function Inventory() {
			pileOfStuff = new Dictionary();
		}
		
		public function clone():Inventory {
			//This isn't the most efficient implementation, but it's quick and easy.
			var text:String = this.toText();
			return Inventory.fromText(text);
		}
		
		public function toText():String {
			var text:String = "";
			for (var i:int = 0; i < NUMBER_OF_EQUIPPED_LOCATIONS; ++i) {
				if (equipmentSlots[i] != null) {
					text += "," + String(i) + " 1 " + equipmentSlots[i].id;
				}
			}
			for (var item:Object in pileOfStuff) {
				var count:int = pileOfStuff[item];
				text += "," + "99 " + count + " " + CanBeInInventory(item).id;
			}
			text = text.substr(1); // remove comma from start
			return text;
		}
		
		public static function fromText(text:String, errors:MessageCollector = null):Inventory {
			var inv:Inventory = new Inventory();
			if (Util.nullOrEmpty(text)) {
				return inv;
			}
			var list:Array = text.split(",");
			for each (var entry:String in list) {
				var slotAndContents:Array = entry.split(" ");
				var slot:int = int(slotAndContents[0]);
				var count:int = int(slotAndContents[1]);
				var id:String = slotAndContents[2];
				var item:CanBeInInventory = Inventory.makeOne(id, errors);
				if (item != null) {
					if (slot < 99) {
						inv.equipmentSlots[slot] = item;
					} else {
						inv.addToPileOfStuff(item, count, errors);
					}
				}
			}
			return inv;
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
		public function addToPileOfStuff(item:CanBeInInventory, howMany:int = 1, errors:MessageCollector = null):int {
			if (howMany < 1) {
				var text:String = "Error! Adding " + howMany + " of something to inventory.";
				if (errors == null) {
					Alert.show(text);
				} else {
					errors.add(text);
				}
				return howMany;
			}
			var count:int = pileOfStuff[item];
			if (count == 0) {
				for (var storedItem:Object in pileOfStuff) {
					if (CanBeInInventory(storedItem).id == item.id) {
						// All items with the same id stack. NOTE: this may change in the future if we damage items!
						item = CanBeInInventory(storedItem);
						count = pileOfStuff[item];
					}
				}
			}
			count += howMany;
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
		
		public function findAllMatchingInPileOfStuff(classToFind:Class):Vector.<CanBeInInventory> {
			var pile:Vector.<CanBeInInventory> = new Vector.<CanBeInInventory>();
			for (var item:Object in pileOfStuff) {
				if (item is classToFind) {
					pile.push(item);
				}
			}
			return pile;
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
		
		public static function makeOne(id:String, errors:MessageCollector = null):CanBeInInventory {
			var resource:IInventoryResource = Settings.catalog.retrieveInventoryResource(id, errors);
			return (resource == null ? null : resource.makeOne());
		}
		
		public function addToPileFromText(text:String, errors:MessageCollector = null):void {
			var list:Array = text.split(",");
			for each (var entry:String in list) {
				var splitEntry:Array = entry.split(" ");
				var count:int = (splitEntry.length == 2) ? int(splitEntry[0]) : 1;
				var id:String = splitEntry[splitEntry.length - 1];
				var item:CanBeInInventory = Inventory.makeOne(id, errors);
				if (item != null) {
					addToPileOfStuff(item, count, errors);
				}
			}
		}
		
		public function removeFromAnywhereByText(text:String, errors:MessageCollector = null):void {
			var myErrors:MessageCollector = (errors == null ? new MessageCollector : errors);
			var list:Array = text.split(",");
			for each (var entry:String in list) {
				var countAndId:Array = entry.split(" ");
				var all:Boolean = countAndId[0] == "all";
				var count:int = (countAndId.length == 2) ? int(countAndId[0]) : 1;
				var id:String = countAndId[countAndId.length - 1];
				removeFromAnywhere(all, count, id, myErrors);
			}
			if (errors == null) {
				myErrors.displayIfNotEmpty();
			}
		}
		
		public function hasByText(text:String, errors:MessageCollector = null):Boolean {
			var list:Array = text.split(",");
			for each (var entry:String in list) {
				var countAndId:Array = entry.split(" ");
				var count:int = (countAndId.length == 2) ? int(countAndId[0]) : 1;
				var id:String = countAndId[countAndId.length - 1];
				if (!has(count, id)) {
					return false;
				}
			}
			return true;
		}
		
		private function has(count:int, id:String):Boolean {
			for (var i:int = 0; i < NUMBER_OF_EQUIPPED_LOCATIONS; ++i) {
				if ((equipmentSlots[i] != null) && (equipmentSlots[i].id == id)) {
					if (--count == 0) {
						return true;
					}
				}
			}
			for (var item:Object in pileOfStuff) {
				if ((CanBeInInventory(item).id == id) && (pileOfStuff[item] >= count)) {
					return true;
				}
			}
			return false;
		}
		
		private function removeFromAnywhere(all:Boolean, count:int, id:String, errors:MessageCollector):void {
			for (var i:int = 0; i < NUMBER_OF_EQUIPPED_LOCATIONS; ++i) {
				if ((equipmentSlots[i] != null) && (equipmentSlots[i].id == id)) {
					equipmentSlots[i] = null;
					if (!all && (--count == 0)) {
						return;
					}
				}
			}
			for (var item:Object in pileOfStuff) {
				if (CanBeInInventory(item).id == id) {
					var numberRemaining:int = pileOfStuff[item];
					if (all) {
						numberRemaining = 0;
					} else {
						numberRemaining -= count;
					}
					if (numberRemaining > 0) {
						pileOfStuff[item] = numberRemaining;
					} else {
						delete pileOfStuff[item];
						if (numberRemaining < 0) {
							errors.add("Remove from inventory: not enough " + id + ".");
						}
					}
					return;
				}
			}
			errors.add("Remove from inventory: " + id + " not found.");
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