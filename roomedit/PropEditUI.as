package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.PropImage;
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
			
			var propImage:PropImage = catalog.retrievePropImage(propId);
			propBitmap.bitmapData = propImage.imageData;

			
			ghostCheck.selected = ((propImage.solid & Prop.SOLID) == 0);
			hardCornerCheck.enabled = !ghostCheck.selected;
			fillsTileCheck.enabled = !ghostCheck.selected;
			hardCornerCheck.selected = ((propImage.solid & Prop.HARD_CORNER) != 0);
			shortCheck.selected = ((propImage.solid & Prop.TALL) == 0);
			fillsTileCheck.selected = ((propImage.solid & Prop.FILLS_TILE) != 0);
		}
		
		private function changeSolidness(event:Event):void {
			var propId:String = propCombo.selectedLabel;
			var propImage:PropImage = catalog.retrievePropImage(propId);
			
			if (event.target == ghostCheck) {
				hardCornerCheck.enabled = !ghostCheck.selected;
				fillsTileCheck.enabled = !ghostCheck.selected;
				if (ghostCheck.selected) {
					hardCornerCheck.selected  = false;
					fillsTileCheck.selected = false;
				}
			}
			
			propImage.solid = 0;
			if (!ghostCheck.selected) {
				propImage.solid |= Prop.SOLID;
			}
			if (hardCornerCheck.selected) {
				propImage.solid |= Prop.HARD_CORNER;
			}
			if (!shortCheck.selected) {
				propImage.solid |= Prop.TALL;
			}
			if (fillsTileCheck.selected) {
				propImage.solid |= Prop.FILLS_TILE;
			}
			
			if (propImage.solid == Prop.DEFAULT_SOLIDITY) {
				catalog.deleteXmlAttribute(propId, "solid");
			} else {
				catalog.changeXmlAttribute(propId, "solid", "0x" + propImage.solid.toString(16));
			}
		}
		
	} // end class PropEditUI

}