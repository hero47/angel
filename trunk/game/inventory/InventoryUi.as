package angel.game.inventory {
	import angel.common.ICleanup;
	import angel.common.SimplerButton;
	import angel.game.Icon;
	import flash.display.Bitmap;
	import flash.display.DisplayObject;
	import flash.display.DisplayObjectContainer;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class InventoryUi extends Sprite implements ICleanup {
		
		public static const BACK_COLOR:uint = 0x808080;
		public static const uiImageX:int = 56;
		public static const uiImageY:int = 56;
		
		private static const PILE_HEIGHT:int = uiImageY;
		private static const WINDOW_X:int = 300;
		private static const WINDOW_Y:int = 300 + PILE_HEIGHT;
		// These are the on-screen locations representing each inventory slot
		private static const slotCoords:Vector.<Point> = Vector.<Point>( [ new Point(26, 69), new Point(211, 69) ] );
		private static const slotIconClass:Vector.<Class> = Vector.<Class>( [ Icon.InventoryMainHand, Icon.InventoryOffHand ] );
		
		private var slots:Vector.<InventoryUiSlot> = new Vector.<InventoryUiSlot>(Inventory.NUMBER_OF_EQUIPPED_LOCATIONS + 1);
		
		private static const PILE:int = Inventory.NUMBER_OF_EQUIPPED_LOCATIONS;
		private var xInventory:int;
		private var yInventory:int;
		
		public var inventory:Inventory;
		
		public function InventoryUi(parent:DisplayObjectContainer, inventory:Inventory) {
			this.inventory = inventory;
			parent.addChild(this);
			
			drawBackground();
			addSlots();
			addDraggables();
		}
		
		private function drawBackground():void {
			graphics.beginFill(BACK_COLOR, 0.5);
			graphics.drawRect(0, 0, parent.stage.stageWidth, parent.stage.stageHeight);
			graphics.endFill();
			
			xInventory = (parent.stage.stageWidth - WINDOW_X) / 2;
			yInventory = (parent.stage.stageHeight - WINDOW_Y) / 2;
			graphics.lineStyle(4, 0x0, 1);
			graphics.beginFill(0xffffff, 1);
			graphics.drawRect(xInventory, yInventory, WINDOW_X, WINDOW_Y);
			
			var bitmap:Bitmap = new Bitmap(Icon.bitmapData(Icon.InventoryBackground));
			bitmap.x = xInventory;
			bitmap.y = yInventory;
			addChild(bitmap);
			
			var doneButton:SimplerButton = new SimplerButton("Done", closeInventory);
			doneButton.x = xInventory + WINDOW_X - doneButton.width - 5;
			doneButton.y = yInventory + 5;
			addChild(doneButton);
		}
		
		private function addSlots():void {
			for (var i:int = 0; i < Inventory.NUMBER_OF_EQUIPPED_LOCATIONS; ++i) {
				slots[i] = new InventoryUiSlot(i, this, slotCoords[i].x + xInventory, slotCoords[i].y + yInventory, slotIconClass[i]);
				addChild(slots[i]);
			}
			
			slots[PILE] = new InventoryUiPile(PILE, this, xInventory, yInventory + WINDOW_Y - PILE_HEIGHT, new Point(WINDOW_X, PILE_HEIGHT));
			addChild(slots[PILE]);
		}
		
		private function addDraggables():void {
			for (var i:int = 0; i < Inventory.NUMBER_OF_EQUIPPED_LOCATIONS; ++i) {
				var item:CanBeInInventory = inventory.itemInSlot(i);
				if (item != null) {
					var draggable:InventoryUiDraggable = new InventoryUiDraggable(this, item, 1, slots[i]);
					slots[i].fillWith(draggable);
					addChild(draggable);
				}
			}
			InventoryUiPile(slots[PILE]).fillFrom(inventory.everythingInPileOfStuff());
		}
		
		public function cleanup():void {
			while (numChildren > 0) {
				var child:DisplayObject = getChildAt(0);
				if (child is ICleanup) {
					ICleanup(getChildAt(0)).cleanup();
				} else {
					removeChildAt(0);
				}
			}
			slots = null;
			if (parent != null) {
				parent.removeChild(this);
			}
		}
		
		public function dropSlotHit(dragging:InventoryUiDraggable):InventoryUiSlot {
			for (var i:int = 0; i <= PILE; ++i) {
				if (slots[i].hitTestObject(dragging)) {
					return slots[i];
				}
			}
			
			return null;
		}
		
		public function defaultPile():InventoryUiSlot {
			return slots[PILE];
		}
		
		private function closeInventory(event:Event):void {
			cleanup();
		}
		
	}

}