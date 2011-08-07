package angel.game.inventory {
	import angel.common.Assert;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	 //NOTE: No provision for scrolling; if there are too many items they will overflow lower edge.
	public class InventoryUiPile extends InventoryUiSlot {
		
		private var contents:Vector.<InventoryUiDraggable>;
		private var right:int;
		private var numberAcross:int;
		private var nextPositionIndex:int;
		
		public function InventoryUiPile(slotNum:int, parentUi:InventoryUi, x:int, y:int, width:int, height:int) {
			numberAcross = width / InventoryUi.SLOT_IMAGE_WIDTH;
			var numberTall:int = height / InventoryUi.SLOT_IMAGE_HEIGHT;
			var pileImageWidth:int = InventoryUi.SLOT_IMAGE_WIDTH * numberAcross;
			var pileImageHeight:int = InventoryUi.SLOT_IMAGE_HEIGHT * numberTall;
			
			graphics.lineStyle(1, 0x0, 1);
			graphics.beginFill(0xffffff, 1);
			graphics.drawRect(0, 0, pileImageWidth, pileImageHeight);
			graphics.lineStyle(1, 0x808080, 0.5);
			for (var i:int = InventoryUi.SLOT_IMAGE_WIDTH; i < width; i += InventoryUi.SLOT_IMAGE_WIDTH) {
				graphics.moveTo(i, 0);
				graphics.lineTo(i, pileImageHeight);
			}
			for (i = InventoryUi.SLOT_IMAGE_HEIGHT; i < height; i += InventoryUi.SLOT_IMAGE_HEIGHT) {
				graphics.moveTo(0, i);
				graphics.lineTo(pileImageWidth, i);
			}
			super(slotNum, parentUi, x, y);
		}
		
		override public function cleanup():void {
			contents = null;
			super.cleanup();
		}
		
		private function setItemPositionFromIndex(draggable:InventoryUiDraggable, index:int):void {
			draggable.x = (index % numberAcross) * InventoryUi.SLOT_IMAGE_WIDTH + this.x;
			draggable.y = int(index / numberAcross) * InventoryUi.SLOT_IMAGE_HEIGHT + this.y;
		}
		
		public function fillFrom(list:Vector.<CanBeInInventory>):void {
			contents = new Vector.<InventoryUiDraggable>();
			nextPositionIndex = 0;
			for each (var item:CanBeInInventory in list) {
				var count:int = parentUi.inventory.countSpecificItemInPileOfStuff(item);
				var draggable:InventoryUiDraggable = new InventoryUiDraggable(parentUi, item, count, this);
				setItemPositionFromIndex(draggable, nextPositionIndex++);
				parentUi.addChild(draggable);
				contents.push(draggable);
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
				setItemPositionFromIndex(draggedItem, nextPositionIndex++);
				draggedItem.currentSlot = this;
				contents.push(draggedItem);
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
				leftover.x = removedItem.x;
				leftover.y = removedItem.y;
				parentUi.addChild(leftover);
				contents[indexInContents] = leftover;
				removedItem.adjustCount(1);
			} else { // remove it
				contents.splice(indexInContents, 1);
				for (var i:int = indexInContents; i < contents.length; i++ ) { // Move the others over to fill gap
					setItemPositionFromIndex(contents[i], indexInContents);
				}
				right -= InventoryUi.SLOT_IMAGE_WIDTH;
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