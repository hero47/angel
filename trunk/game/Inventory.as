package angel.game {
	import angel.common.Alert;
	import angel.common.Assert;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class Inventory {
		
		private var items:Dictionary; // mapping from CanBeInInventory to integer number of items
		
		public function Inventory() {
			items = new Dictionary();
		}
		
		public function add(item:CanBeInInventory, howMany:int = 1):void {
			if (howMany < 1) {
				Alert.show("Error! Adding " + howMany + " of something to inventory.");
				return;
			}
			var currentCount:int = items[item];
			items[item] = currentCount + howMany;
		}
		
		public function remove(specificItem:CanBeInInventory, howMany:int):void {
			var currentCount:int = items[specificItem];
			if (currentCount == 0) {
				Alert.show("Error! Removing something that's not in inventory");
				return;
			}
			if (currentCount <= howMany) {
				if (currentCount < howMany) {
					Alert.show("Error! Removing " + howMany + " items when inventory contains " + currentCount);
				}
				delete items[specificItem];
			} else {
				items[specificItem] = currentCount - howMany;
			}
		}
		
		public function removeAll(specificItem:CanBeInInventory):void {
			var currentCount:int = items[specificItem];
			if (currentCount == 0) {
				Alert.show("Error! Removing something that's not in inventory");
				return;
			}
			delete items[specificItem];
		}
		
		public function findA(classToFind:Class):CanBeInInventory {
			for (var item:Object in items) {
				if (item is classToFind) {
					return CanBeInInventory(item);
				}
			}
			return null;
		}
		
		public function countSpecificItem(specificItem:Object):int {
			return items[specificItem];
		}
		
		public function count(classToFind:Class):int {
			var count:int = 0;
			for (var item:Object in items) {
				if (item is classToFind) {
					count += items[item];
				}
			}
			return count;
		}
		
		public function slotsUsed():int {
			var count:int = 0;
			for (var item:Object in items) {
				count++;
			}
			return count;
		}
		
		public function debugListContents(header:String = null):void {
			if (header != null) {
				trace(header);
			}
			for (var item:Object in items) {
				trace(item, items[item]);
			}
			
		}
		
	}

}