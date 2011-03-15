package angel.roomedit {
	import angel.common.Alert;
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.Util;
	import angel.common.WalkerImage;
	import angel.game.Entity;
	import fl.controls.ComboBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class NpcPalette extends Sprite implements IRoomEditorPalette {
		private var catalog:CatalogEdit;
		private var room:RoomLight;
		private var walkerFacingFront:Bitmap;
		private var walkerCombo:ComboBox;
		private var locationText:TextField;
		private var available:Boolean;
		
		public function NpcPalette(catalog:CatalogEdit, room:RoomLight) {
			this.catalog = catalog;
			this.room = room;
			
			graphics.beginFill(EditorSettings.PALETTE_BACKCOLOR, 1);
			graphics.drawRect(0, 0, EditorSettings.PALETTE_XSIZE, EditorSettings.PALETTE_YSIZE);
			
			walkerFacingFront = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			walkerFacingFront.x = (this.width - walkerFacingFront.width) / 2;
			walkerFacingFront.y = 10;
			addChild(walkerFacingFront);
			
			var walkerChooser:Sprite = catalog.createChooser(CatalogEntry.WALKER, EditorSettings.PALETTE_XSIZE - 10);
			walkerChooser.x = (this.width - walkerChooser.width) / 2;
			walkerChooser.y = Prop.HEIGHT + 20;
			addChild(walkerChooser);
			walkerCombo = ComboBox(walkerChooser.getChildAt(0));
			walkerCombo.addEventListener(Event.CHANGE, changeWalker);
			
			locationText = Util.textBox("", EditorSettings.PALETTE_XSIZE, Util.DEFAULT_TEXT_HEIGHT, TextFormatAlign.CENTER);
			locationText.y = walkerChooser.y + walkerChooser.height + 10;
			addChild(locationText);
			
			walkerCombo.selectedIndex = 0;
			changeWalker(null);
			
			room.addEventListener(Event.INIT, roomLoaded);
		}
		
		private function changeWalker(event:Event):void {
			var walkerId:String = walkerCombo.value;
			
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(walkerId);
			walkerFacingFront.bitmapData = walkerImage.bitsFacing(1);
			
			updateAvailability();
		}
		
		private function updateAvailability():void {
			var location:Point = room.find(walkerCombo.value);
			available = (location == null);
			locationText.text = (available ? "Available" : "Location: " + location);
		}

		public function applyToTile(tile:FloorTileEdit):void {
			if (room.occupied(tile.location)) {
				room.removeItemAt(tile.location);
			} else {
				if (available) {
					//CONSIDER: this will need revision if we add resource management
					var prop:Prop = Prop.createFromBitmapData(walkerFacingFront.bitmapData);
					room.addContentItem(prop, CatalogEntry.WALKER, walkerCombo.value, tile.location);
				} else {
					Alert.show("Cannot place " + walkerCombo.value + " -- already in room.");
				}
			}
			updateAvailability();
		}
		
		public function paintWhileDragging():Boolean {
			return false;
		}
		
		private function roomLoaded(event:Event):void {
			if (this.visible) {
				updateAvailability();
			}
		}
		
		// Whenever we become visible, update the walker location text
		override public function set visible(value:Boolean):void {
			super.visible = value;
			if (this.visible) {
				updateAvailability();
			}
		}
		
	}

}