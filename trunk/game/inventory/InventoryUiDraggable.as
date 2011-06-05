package angel.game.inventory {
	import angel.common.ICleanup;
	import angel.common.Util;
	import angel.game.Icon;
	import flash.display.Bitmap;
	import flash.display.Sprite;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	import flash.ui.Mouse;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InventoryUiDraggable extends Sprite implements ICleanup {
		
		private var parentUi:InventoryUi;
		private var item:CanBeInInventory;
		private var count:int;
		public var currentSlot:InventoryUiSlot;
		private var countText:TextField;
		
		private var xHome:int; // coords that I'm being dragged away from
		private var yHome:int;
		private var legalSlotCurrentlyHoveredOver:InventoryUiSlot;
		
		public function InventoryUiDraggable(parentUi:InventoryUi, item:CanBeInInventory, count:int, currentSlot:InventoryUiSlot) {
			this.parentUi = parentUi;
			this.item = item;
			this.count = count;
			this.currentSlot = currentSlot;
			graphics.lineStyle(1, 0x0, 1);
			graphics.beginFill(0xffffff, 1);
			graphics.drawRect(0, 0, InventoryUi.uiImageX, InventoryUi.uiImageY);
			
			var bitmap:Bitmap = new Bitmap(Icon.bitmapData(item.iconClass));
			bitmap.x = (InventoryUi.uiImageX - bitmap.width) / 2;
			bitmap.y = (InventoryUi.uiImageY - bitmap.height) / 2;
			bitmap.alpha = 0.5;
			addChild(bitmap);
			
			var text:TextField = Util.textBox(item.displayName, InventoryUi.uiImageX, 20);
			text.wordWrap = true;
			text.height = InventoryUi.uiImageY;
			addChild(text);
			
			if (count != 1) {
				createCountText();
			}
			
			mouseChildren = false;
			
			addEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
		}
		
		public function cleanup():void {
			removeEventListener(MouseEvent.MOUSE_DOWN, mouseDownListener);
			removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			removeEventListener(MouseEvent.MOUSE_UP, mouseMoveListener);
			if (countText != null) {
				removeChild(countText);
				countText = null;
			}
			if (parent != null) {
				parent.removeChild(this);
			}
		}
		
		public function get inventoryItem():CanBeInInventory {
			return item;
		}
		
		private function mouseDownListener(event:MouseEvent):void {
			xHome = this.x;
			yHome = this.y;
			addEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			addEventListener(MouseEvent.MOUSE_MOVE, mouseMoveListener);
			parent.addChild(this); // move to top
			startDrag();
		}
		
		private function mouseMoveListener(event:MouseEvent):void {
			var mouseSlot:InventoryUiSlot = parentUi.dropSlotHit(this);
			if (mouseSlot == legalSlotCurrentlyHoveredOver) {
				return;
			}
			if (legalSlotCurrentlyHoveredOver != null) {
				legalSlotCurrentlyHoveredOver.dragOver(null);
				legalSlotCurrentlyHoveredOver = null;
			}
			if (mouseSlot != null) {
				legalSlotCurrentlyHoveredOver = mouseSlot.dragOver(item);
			}
		}
		
		private function mouseUpListener(event:MouseEvent):void {
			removeEventListener(MouseEvent.MOUSE_UP, mouseUpListener);
			removeEventListener(MouseEvent.MOUSE_MOVE, mouseMoveListener);
			stopDrag();
			if (legalSlotCurrentlyHoveredOver == null) {
				this.x = xHome;
				this.y = yHome;
			} else {
				legalSlotCurrentlyHoveredOver.dragOver(null);
				if (legalSlotCurrentlyHoveredOver == currentSlot) {
					this.x = xHome;
					this.y = yHome;
				} else {
					currentSlot.dragOut(this);
					legalSlotCurrentlyHoveredOver.dropIn(this);
					currentSlot = legalSlotCurrentlyHoveredOver;
				}
				legalSlotCurrentlyHoveredOver = null;
			}
		}
		
		public function adjustCount(newCount:int):void {
			count = newCount;
			if (countText != null) {
				removeChild(countText);
				countText = null;
			}
			if (count != 1) {
				createCountText();
			}
		}
		
		private function createCountText():void {
			countText = Util.textBox(String(count), 20, 20, TextFormatAlign.RIGHT, false, 0x006400);
			countText.x = this.width - 20;
			countText.y = this.height - 20;
			addChild(countText);
		}
	}

}