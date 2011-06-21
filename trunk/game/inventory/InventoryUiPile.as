package angel.game.inventory {
	import angel.common.Assert;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// WARNING: currently supports only a single row of items.
	public class InventoryUiPile extends InventoryUiSlot {
		
		private var contents:Vector.<InventoryUiDraggable>;
		private var right:int;
		
		public function InventoryUiPile(slotNum:int, parentUi:InventoryUi, x:int, y:int, size:Point) {
			graphics.lineStyle(1, 0x0, 1);
			graphics.beginFill(0xffffff, 1);
			graphics.drawRect(0, 0, size.x, size.y);
			graphics.lineStyle(1, 0x808080, 0.5);
			for (var i:int = InventoryUi.uiImageX; i < size.x; i += InventoryUi.uiImageX) {
				graphics.moveTo(i, 0);
				graphics.lineTo(i, InventoryUi.uiImageY);
			}
			super(slotNum, parentUi, x, y);
		}
		
		override public function cleanup():void {
			contents = null;
			super.cleanup();
		}
		
		public function fillFrom(list:Vector.<CanBeInInventory>):void {
			contents = new Vector.<InventoryUiDraggable>();
			right = this.x;
			for each (var item:CanBeInInventory in list) {
				var count:int = parentUi.inventory.countSpecificItemInPileOfStuff(item);
				var draggable:InventoryUiDraggable = new InventoryUiDraggable(parentUi, item, count, this);
				draggable.x = right;
				draggable.y = this.y;
				parentUi.addChild(draggable);
				contents.push(draggable);
				right += InventoryUi.uiImageX;
			}
		}
		
		override public function dropIn(draggedItem:InventoryUiDraggable):void {
			var item:CanBeInInventory = draggedItem.inventoryItem;
			Assert.assertTrue(Inventory.isItemLegalInSlot(item, slotNum), "Drop in illegal slot");
			
			var newItem:CanBeInInventory = parentUi.inventory.addToPileOfStuff(item, 1);
			if (newItem != item) {
				draggedItem.inventoryItem = newItem;
			}
			if (parentUi.inventory.countSpecificItemInPileOfStuff(newItem) == 1) {
				draggedItem.x = right;
				draggedItem.y = this.y;
				draggedItem.currentSlot = this;
				contents.push(draggedItem);
				right += InventoryUi.uiImageX;
			} else {
				adjustCountFor(newItem);
				draggedItem.cleanup();
			}
		}
		
		override public function dragOut(removedItem:InventoryUiDraggable):void {
			var item:CanBeInInventory = removedItem.inventoryItem;
			var indexInContents:int = contents.indexOf(removedItem);
			if (indexInContents < 0) {
				Assert.fail("Removed item missing from ui pile");
				return;
			}
			parentUi.inventory.removeFromPileOfStuff(item, 1);
			var numberRemaining:int = parentUi.inventory.countSpecificItemInPileOfStuff(item);
			if (numberRemaining > 0) { // split this stack
				var leftover:InventoryUiDraggable = new InventoryUiDraggable(parentUi, item, numberRemaining, this);
				leftover.x = this.x + (indexInContents * InventoryUi.uiImageX);
				leftover.y = this.y;
				parentUi.addChild(leftover);
				contents[indexInContents] = leftover;
				removedItem.adjustCount(1);
			} else { // remove it
				contents.splice(indexInContents, 1);
				for (var i:int = indexInContents; i < contents.length; i++ ) {
					contents[i].x -= InventoryUi.uiImageX; // Move the others over to fill gap
				}
				right -= InventoryUi.uiImageX;
			}
		}
		
		private function adjustCountFor(item:CanBeInInventory):void {
			for each (var draggable:InventoryUiDraggable in contents) {
				if (draggable.inventoryItem.stacksWith(item)) {
					var count:int = parentUi.inventory.countSpecificItemInPileOfStuff(item);
					draggable.adjustCount(count);
				}
			}
		}
		
	}

}