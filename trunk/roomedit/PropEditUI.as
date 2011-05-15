package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.Util;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class PropEditUI extends Sprite {

		private var catalog:CatalogEdit;
		private var propBitmap:Bitmap;
		private var propCombo:ComboBox;
		private var ghostCheck:CheckBox;
		private var hardCornerCheck:CheckBox;
		private var shortCheck:CheckBox;
		private var fillsTileCheck:CheckBox;

		private static const SOLID_COMBO_MASK:uint = (Prop.SOLID | Prop.HARD_CORNER);
		
		private static const WIDTH:int = 220;
		
		public function PropEditUI(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			
			propBitmap = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			propBitmap.x = (WIDTH - Prop.WIDTH) / 2;
			addChild(propBitmap);
			
			var propChooser:Sprite = catalog.createChooser(CatalogEntry.PROP, WIDTH);
			propCombo = ComboBox(propChooser.getChildAt(0));
			propCombo.addEventListener(Event.CHANGE, changeProp);
			propChooser.y = propBitmap.y + propBitmap.height + 10;
			addChild(propChooser);
			
			ghostCheck = Util.createCheckboxEditControlBelow(propChooser, "Ghost/Hologram", 120, changeSolidness);
			hardCornerCheck = Util.createCheckboxEditControlBelow(ghostCheck, "Hard corners", 120, changeSolidness);
			shortCheck = Util.createCheckboxEditControlBelow(hardCornerCheck, "Short", 120, changeSolidness);
			fillsTileCheck = Util.createCheckboxEditControlBelow(shortCheck, "Fills Tile", 120, changeSolidness);

			if (startId == null) {
				propCombo.selectedIndex = 0;
			} else {
				for (var i:int = 0; i < propCombo.length; i++) {
					if (propCombo.getItemAt(i).label == startId) {
						propCombo.selectedIndex = i;
						break;
					}
				}
			}

			changeProp(null);
		}
		
		private function changeProp(event:Event):void {
			var propId:String = propCombo.selectedLabel;

			var resource:RoomContentResource = catalog.retrievePropResource(propId);
			propBitmap.bitmapData = resource.standardImage();
			
			ghostCheck.selected = ((resource.solidness & Prop.SOLID) == 0);
			hardCornerCheck.enabled = !ghostCheck.selected;
			fillsTileCheck.enabled = !ghostCheck.selected;
			hardCornerCheck.selected = ((resource.solidness & Prop.HARD_CORNER) != 0);
			shortCheck.selected = ((resource.solidness & Prop.TALL) == 0);
			fillsTileCheck.selected = ((resource.solidness & Prop.FILLS_TILE) != 0);
		}
		
		private function changeSolidness(event:Event):void {
			var propId:String = propCombo.selectedLabel;
			var resource:RoomContentResource = catalog.retrievePropResource(propId);
			
			if (event.target == ghostCheck) {
				hardCornerCheck.enabled = !ghostCheck.selected;
				fillsTileCheck.enabled = !ghostCheck.selected;
				if (ghostCheck.selected) {
					hardCornerCheck.selected  = false;
					fillsTileCheck.selected = false;
				}
			}
			
			resource.solidness = 0;
			if (!ghostCheck.selected) {
				resource.solidness |= Prop.SOLID;
			}
			if (hardCornerCheck.selected) {
				resource.solidness |= Prop.HARD_CORNER;
			}
			if (!shortCheck.selected) {
				resource.solidness |= Prop.TALL;
			}
			if (fillsTileCheck.selected) {
				resource.solidness |= Prop.FILLS_TILE;
			}
			
			if (resource.solidness == Prop.DEFAULT_SOLIDITY) {
				catalog.deleteXmlAttribute(propId, "solid");
			} else {
				catalog.changeXmlAttribute(propId, "solid", "0x" + resource.solidness.toString(16));
			}
		}
		
	} // end class PropEditUI

}