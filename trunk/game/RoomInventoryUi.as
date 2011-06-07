package angel.game {
	import angel.common.SimplerButton;
	import angel.game.inventory.Inventory;
	import angel.game.inventory.InventoryUi;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class RoomInventoryUi extends InventoryUi {
		private var room:Room;
		private var entity:ComplexEntity;
		private var commitButtonText:String;
		private var commitActionCost:int;
		private var inventoryBeingManipulated:Inventory;
		
		public function RoomInventoryUi(room:Room, entity:ComplexEntity, 
					commitButtonText:String = "Done", commitActionCost:int = 0) {
			this.room = room;
			this.entity = entity;
			this.commitButtonText = commitButtonText;
			this.commitActionCost = commitActionCost;
			
			room.suspendUi(this);
			inventoryBeingManipulated = entity.inventory.clone();
			super(room.parent, inventoryBeingManipulated);
			
		}
		
		override public function cleanup():void {
			super.cleanup();
			room.restoreUiAfterSuspend(this);
			room = null;
		}
		
		override protected function addButtons():void {
			var enableCommit:Boolean = (entity.actionsRemaining >= commitActionCost);
			var doneButton:SimplerButton = new SimplerButton(commitButtonText, commitAndCloseInventory,
						enableCommit ? BUTTON_COLOR : 0x808080, enableCommit ? 0x0 : 0x808080);
			doneButton.resizeToFitText(SimplerButton.WIDTH);
			doneButton.x = xInventory + WINDOW_X - doneButton.width - 5;
			doneButton.y = yInventory + 5;
			addChild(doneButton);
			if (!enableCommit) {
				doneButton.enabled = false;
				doneButton.mouseEnabled = false;
			}
			
			var cancelButton:SimplerButton = new SimplerButton("Cancel", closeInventory, BUTTON_COLOR);
			cancelButton.x = xInventory + WINDOW_X - cancelButton.width - 5;
			cancelButton.y = doneButton.y + doneButton.height + 5;
			addChild(cancelButton);
		}
		
		private function commitAndCloseInventory(event:Event):void {
			entity.inventory = inventoryBeingManipulated;
			entity.actionsRemaining -= commitActionCost;
			closeInventory(event);
		}
		
	}

}