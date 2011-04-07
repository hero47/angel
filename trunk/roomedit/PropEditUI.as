package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.PropImage;
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
		private var solidCombo:ComboBox;
		private var shortCheck:CheckBox;
		
		private static const solidChoices:Array = [
				{ label:"Ghost/Hologram", data:0 },
				{ label:"'Soft' Solid (normal)", data:Prop.SOLID },
				{ label:"'Hard' Solid (adjacent corners block)", data:(Prop.SOLID | Prop.HARD_CORNER) } 
		]
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
			
			solidCombo = new ComboBox();
			solidCombo.width = WIDTH;
			for (var i:int = 0; i < solidChoices.length; i++) {
				solidCombo.addItem(solidChoices[i]);
			}
			solidCombo.addEventListener(Event.CHANGE, changeSolidness);
			solidCombo.y = propChooser.y + propCombo.height + 10;
			addChild(solidCombo);
			
			shortCheck = new CheckBox();
			shortCheck.label = "Short";
			shortCheck.y = solidCombo.y + solidCombo.height + 10;
			shortCheck.addEventListener(Event.CHANGE, changeSolidness);
			addChild(shortCheck);

			if (startId == null) {
				propCombo.selectedIndex = 0;
			} else {
				for (i = 0; i < propCombo.length; i++) {
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

			var solidComboData:uint = propImage.solid & SOLID_COMBO_MASK;
			for (var i:int = 0; i < solidChoices.length; i++) {
				if (solidCombo.getItemAt(i).data == solidComboData) {
					solidCombo.selectedIndex = i;
					break;
				}
			}
			
			shortCheck.selected = ((propImage.solid & Prop.TALL) == 0);
		}
		
		private function changeSolidness(event:Event):void {
			var propId:String = propCombo.selectedLabel;
			var propImage:PropImage = catalog.retrievePropImage(propId);
			propImage.solid = solidCombo.selectedItem.data;
			if (!shortCheck.selected) {
				propImage.solid |= Prop.TALL;
			}
			if (propImage.solid == Prop.DEFAULT_SOLIDITY) {
				catalog.deleteXmlAttribute(propId, "solid");
			} else {
				catalog.changeXmlAttribute(propId, "solid", "0x" + propImage.solid.toString(16));
			}
		}
		
	} // end class PropEditUI

}