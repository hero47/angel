package angel.game.inventory {
	import angel.common.Assert;
	import angel.common.ICleanup;
	import flash.display.Bitmap;
	import flash.display.Shape;
	import flash.display.Sprite;
	import flash.geom.ColorTransform;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	// if iconClass is provided, slot is the size and shape of that icon
	// otherwise it's a white rectangle with black outline in the specified size
	public class InventoryUiSlot extends Sprite implements ICleanup {
		protected var slotNum:int;
		protected var parentUi:InventoryUi;
		private var myContent:InventoryUiDraggable;
		
		private var hilight:Shape;
		
		public function InventoryUiSlot(slotNum:int, parentUi:InventoryUi, x:int, y:int, iconClass:Class = null) {
			this.slotNum = slotNum;
			this.parentUi = parentUi;
			
			if (iconClass != null) {
				var bitmap:Bitmap = new iconClass();
				addChild(bitmap);
			}
			this.x = x;
			this.y = y;
			this.mouseEnabled = false;
			
			hilight = new Shape();
			hilight.graphics.beginFill(0x00ffff, 0.7);
			hilight.graphics.drawRect(0, 0, this.width, this.height);
		}
		
		public function cleanup():void {
			if (hilight.parent != null) {
				hilight.parent.removeChild(hilight);
			}
			hilight = null;
			if (parent != null) {
				parent.removeChild(this);
			}
		}
		
		// Hilight this slot if item can legally be dropped here (de-hilight if item is null or illegal)
		// return this if item can be dropped here, null if not
		public function dragOver(draggedItem:CanBeInInventory):InventoryUiSlot {
			if ((draggedItem == null) || !Inventory.isItemLegalInSlot(draggedItem, slotNum)) {
				if (hilight.parent != null) {
					hilight.parent.removeChild(hilight);
				}
				return null;
			}
			if (hilight.parent == null) {
				hilight.x = this.x;
				hilight.y = this.y;
				parent.addChild(hilight);
			}
			return this;
		}
		
		public function fillWith(draggedItem:InventoryUiDraggable):void {
			var item:CanBeInInventory = draggedItem.inventoryItem;
			Assert.assertTrue(Inventory.isItemLegalInSlot(item, slotNum), "Drop in illegal slot");
			
			draggedItem.x = this.x;
			draggedItem.y = this.y;
			draggedItem.currentSlot = this;
			myContent = draggedItem;
		}
		
		public function dropIn(draggedItem:InventoryUiDraggable):void {
			var oldContent:InventoryUiDraggable = myContent;
			var slotThisItemCameFrom:InventoryUiSlot = draggedItem.currentSlot;
			
			var item:CanBeInInventory = draggedItem.inventoryItem;
			fillWith(draggedItem);			
			parentUi.inventory.equip(item, slotNum, false);
			if (oldContent != null) {
				if (Inventory.isItemLegalInSlot(oldContent.inventoryItem, slotThisItemCameFrom.slotNum)) {
					slotThisItemCameFrom.dropIn(oldContent);
				} else {
					parentUi.defaultPile().dropIn(oldContent);
				}
			}
		}
		
		public function dragOut(removedItem:InventoryUiDraggable):void {
			parentUi.inventory.unequip(slotNum, false);
			myContent = null;
		}
		
	}

}