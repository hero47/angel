package angel.roomedit {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.CatalogEntry;
	import angel.common.FloorTile;
	import angel.common.KludgeDialogBox;
	import angel.common.Prop;
	import angel.common.PropImage;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;

	public class PropPalette extends ContentPaletteCommonCode {
		
		public function PropPalette(catalog:CatalogEdit, room:RoomLight) {
			super(catalog, room);			
			itemCombo.selectedIndex = 0;
			itemComboBoxChanged(null);
		}
		
		override public function get tabLabel():String {
			return "Props";
		}
		
		override protected function roomLoaded(event:Event):void {
			clearSelection();
		}
		
		override protected function userClickedOccupiedTile(location:Point):void {
			if (room.typeOfItemAt(location) == CatalogEntry.PROP) {
				locationOfCurrentSelection = location;
				changeSelectionOnMapTo(location);
			}
		}
		
		override protected function itemComboBoxChanged(event:Event = null):void {
			var propId:String = itemCombo.selectedLabel;
			
			var propImage:PropImage = catalog.retrievePropImage(propId);
			itemImage.bitmapData = propImage.imageData;
		}
		
		override protected function attemptToCreateOneAt(location:Point):void {
			//CONSIDER: this will need revision if we add resource management
			var prop:Prop = Prop.createFromBitmapData(itemImage.bitmapData);
			room.addContentItem(prop, CatalogEntry.PROP, itemCombo.selectedLabel, location);
			locationOfCurrentSelection = location;
			changeSelectionOnMapTo(location);
		}
		
		override protected function removeSelectedItem(event:Event):void {
			super.removeSelectedItem(event);
			clearSelection();
		}
		
	} // end class PropPalette

}
