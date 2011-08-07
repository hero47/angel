package angel.game.inventory {
	import angel.common.ICleanup;
	import angel.common.SimplerButton;
	import angel.game.Icon;
	import angel.game.Room;
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
	
	//NOTE: if there were a side panel that could produce any inventory item in the catalog as a InventoryUiDraggable,
	//then this could be used in the Editor to set inventory for characters.  A version might also be used for the "load-out"
	//portion of the game, where the player equips the character(s) that will be going on a mission.  So it seems worth
	//going to some extra effort to keep this free of entanglement with room-specific code.  To that end, I'm going to
	//make a separate subclass to interface between InventoryUi and rooms.
	public class InventoryUi extends Sprite implements ICleanup {
		
		protected static const BACK_COLOR:uint = 0xFCFBD5;
		protected static const BUTTON_COLOR:uint = 0xff6a00;
		public static const SLOT_IMAGE_WIDTH:int = 56;
		public static const SLOT_IMAGE_HEIGHT:int = 56;
		
		private static const STANDARD_PILE_HEIGHT:int = SLOT_IMAGE_HEIGHT;
		private static const STANDARD_INVENTORY_WIDTH:int = 300;
		private static const STANDARD_INVENTORY_HEIGHT:int = 300 + STANDARD_PILE_HEIGHT;
		// These are the on-screen locations representing each inventory slot
		private static const slotCoords:Vector.<Point> = Vector.<Point>( [ new Point(26, 69), new Point(211, 69) ] );
		private static const slotIconClass:Vector.<Class> = Vector.<Class>( [ Icon.InventoryMainHand, Icon.InventoryOffHand ] );
		
		//NOTE: indexes to these must match the slot indexes in Inventory!
		protected var slots:Vector.<InventoryUiSlot> = new Vector.<InventoryUiSlot>(Inventory.NUMBER_OF_EQUIPPED_LOCATIONS + 1);
		
		protected static const PILE:int = Inventory.NUMBER_OF_EQUIPPED_LOCATIONS;
		
		protected var xInventory:int;
		protected var yInventory:int;
		protected var inventoryWidth:int;
		protected var inventoryHeight:int;
		
		public var inventory:Inventory;
		
		public function InventoryUi(parent:DisplayObjectContainer, inventory:Inventory, pileFilterClass:Class = null) {
			this.inventory = inventory;
			parent.addChild(this);
			
			drawBackground();
			addButtons();
			addSlots();
			addDraggables(pileFilterClass);
			
		}
		
		protected function drawBackground():void {
			drawBackgroundFromDetails(Icon.InventoryBackground, STANDARD_INVENTORY_WIDTH, STANDARD_INVENTORY_HEIGHT);
		}
		
		protected function drawBackgroundFromDetails(bitmapClass:Class, totalWidth:int, totalHeight:int):void {
			inventoryWidth = totalWidth;
			inventoryHeight = totalHeight;
			graphics.beginFill(BACK_COLOR, 0.5);
			graphics.drawRect(0, 0, parent.stage.stageWidth, parent.stage.stageHeight);
			graphics.endFill();
			
			xInventory = (parent.stage.stageWidth - totalWidth) / 2;
			yInventory = (parent.stage.stageHeight - totalHeight) / 2;
			graphics.lineStyle(4, 0x0, 1);
			graphics.beginFill(BACK_COLOR, 1);
			graphics.drawRect(xInventory-2, yInventory-2, totalWidth+4, totalHeight+4); // put border entirely outside
			
			if (bitmapClass != null) {
				var bitmap:Bitmap = new Bitmap(Icon.bitmapData(bitmapClass));
				bitmap.x = xInventory;
				bitmap.y = yInventory;
				addChild(bitmap);
			}
		}
		
		protected function addButtons():void {
			var doneButton:SimplerButton = new SimplerButton("Done", closeInventory, BUTTON_COLOR);
			doneButton.x = xInventory + STANDARD_INVENTORY_WIDTH - doneButton.width - 5;
			doneButton.y = yInventory + 5;
			addChild(doneButton);
		}
		
		protected function addSlots():void {
			for (var i:int = 0; i < Inventory.NUMBER_OF_EQUIPPED_LOCATIONS; ++i) {
				slots[i] = new InventoryUiSlot(i, this, slotCoords[i].x + xInventory, slotCoords[i].y + yInventory, slotIconClass[i]);
				addChild(slots[i]);
			}
			
			slots[PILE] = new InventoryUiPile(PILE, this, xInventory, yInventory + STANDARD_INVENTORY_HEIGHT - STANDARD_PILE_HEIGHT,
					STANDARD_INVENTORY_WIDTH, STANDARD_PILE_HEIGHT);
			addChild(slots[PILE]);
		}
		
		protected function addDraggables(pileFilterClass:Class = null):void {
			for (var i:int = 0; i < Inventory.NUMBER_OF_EQUIPPED_LOCATIONS; ++i) {
				var item:CanBeInInventory = inventory.itemInSlot(i);
				if (item != null) {
					var draggable:InventoryUiDraggable = new InventoryUiDraggable(this, item, 1, slots[i]);
					slots[i].fillWith(draggable);
					addChild(draggable);
				}
			}
			InventoryUiPile(slots[PILE]).fillFrom(inventory.everythingInPileOfStuff(pileFilterClass));
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
				if ((slots[i] != null) && (slots[i].hitTestObject(dragging))) {
					return slots[i];
				}
			}
			
			return null;
		}
		
		public function defaultPile():InventoryUiSlot {
			return slots[PILE];
		}
		
		protected function closeInventory(event:Event):void {
			cleanup();
		}
		
	}

}