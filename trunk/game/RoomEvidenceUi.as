package angel.game {
	import angel.common.Evidence;
	import angel.common.SimplerButton;
	import angel.common.Util;
	import angel.game.ComplexEntity;
	import angel.game.Icon;
	import angel.game.inventory.InventoryUi;
	import angel.game.inventory.InventoryUiPile;
	import angel.game.inventory.InventoryUiSlot;
	import angel.game.Room;
	import flash.display.DisplayObjectContainer;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class RoomEvidenceUi extends RoomInventoryUi {
		
		private static const NUMBER_ACROSS:int = 4;
		private static const NUMBER_TALL:int = 3;
		private static const SPACE_ABOVE_PILE:int = (SimplerButton.HEIGHT + 5) * 3;
		private static const SPACE_RIGHT_OF_PILE:int = SimplerButton.WIDTH + 10;
		private static const EVIDENCE_INVENTORY_WIDTH:int = InventoryUi.SLOT_IMAGE_WIDTH * NUMBER_ACROSS + SPACE_RIGHT_OF_PILE;
		private static const EVIDENCE_INVENTORY_HEIGHT:int = InventoryUi.SLOT_IMAGE_HEIGHT * NUMBER_TALL + SPACE_ABOVE_PILE;
		
		public function RoomEvidenceUi(room:Room, entity:ComplexEntity) {
			super(room, entity);			
		}
		
		override protected function drawBackground():void {
			drawBackgroundFromDetails(null, EVIDENCE_INVENTORY_WIDTH, EVIDENCE_INVENTORY_HEIGHT);
			var label:TextField = Util.textBox("Evidence", InventoryUi.SLOT_IMAGE_WIDTH * NUMBER_ACROSS, 30, TextFormatAlign.CENTER);
			label.x = xInventory;
			label.y = SPACE_ABOVE_PILE - label.height + yInventory;
			addChild(label);
		}
		
		override protected function addSlots():void {
			slots[PILE] = new InventoryUiPile(PILE, this, xInventory, yInventory + SPACE_ABOVE_PILE,
				EVIDENCE_INVENTORY_WIDTH - SimplerButton.WIDTH, InventoryUi.SLOT_IMAGE_HEIGHT * NUMBER_TALL);
			addChild(slots[PILE]);
		}
		
		override protected function addDraggables(pileFilterClass:Class = null):void {
			InventoryUiPile(slots[PILE]).fillFrom(inventory.everythingInPileOfStuff(Evidence));
		}
		
	}

}