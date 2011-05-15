package angel.roomedit {
	import angel.common.Alert;
	import angel.common.Catalog;
	import angel.common.CatalogEntry;
	import angel.common.FloorTile;
	import angel.common.KludgeDialogBox;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.Util;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.events.MouseEvent;
	import flash.geom.Point;
	import flash.text.TextField;

	public class PropPalette extends ContentPaletteCommonCode {
		private var scriptFile:FilenameControl;
		
		public function PropPalette(catalog:CatalogEdit, room:RoomLight) {
			super(catalog, room);
			
			graphics.lineStyle(0x000000, 2);
			var lineY:int = itemChooser.y + itemChooser.height + 10;
			graphics.moveTo(0, lineY);
			graphics.lineTo(EditorSettings.PALETTE_XSIZE, lineY);
			
			Util.addBelow(attributeDisplay, itemChooser, 20);
			updateAvailabilityAndAttributes();
			
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
			var resource:RoomContentResource = catalog.retrieveRoomContentResource(propId, CatalogEntry.PROP);
			itemImage.bitmapData = resource.standardImage();
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
			updateAvailabilityAndAttributes();
		}
		
		override protected function createAttributeDisplay():Sprite {
			var holder:Sprite = new Sprite();
			
			var title:TextField = Util.textBox("NOTE: this section applies to selected prop, which may not match top section!",
				EditorSettings.PALETTE_XSIZE);
			title.height = 60;
			title.multiline = true;
			title.wordWrap = true;
			holder.addChild(title);
			
			holder.addChild(removeButton); //move it from main palette down into here
			removeButton.y = title.y + title.height;
			
			var talkLabel:TextField = Util.textBox("Conversation/Script file:", EditorSettings.PALETTE_XSIZE-20);
			Util.addBelow(talkLabel, title, 25);
			scriptFile = FilenameControl.createBelow(talkLabel, true, null, 0, EditorSettings.PALETTE_XSIZE-10, function(event:Event):void {
				changeAttribute("script", scriptFile.text);
			});
			
			return holder;
		}
		
		override protected function updateAvailabilityAndAttributes():void {
			trace("prop palette update, currentSelection=", currentSelection);
			if (currentSelection != null) {
				attributeDisplay.visible = true;
				var attributes:Object = room.attributesOfItemAt(locationOfCurrentSelection);
				if (attributes == null) {
					scriptFile.text = "";
				} else {
					scriptFile.text = attributes["script"];
				}
			} else {
				attributeDisplay.visible = false;
			}
		}
		
		
	} // end class PropPalette

}
