package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.PropImage;
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
		
		private static const solidChoices:Array = [
				{ label:"Ghost/Hologram", data:Prop.GHOST },
				{ label:"'Soft' Solid (normal)", data:Prop.SOLID },
				{ label:"'Hard' Solid (adjacent corners block)", data:Prop.HARD_SOLID } 
		]
		
		private static const WIDTH:int = 220;
		
		public function PropEditUI(catalog:CatalogEdit) {
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
			solidCombo.addEventListener(Event.CHANGE, changeSolid);
			solidCombo.y = propChooser.y + propCombo.height + 10;
			addChild(solidCombo);

			propCombo.selectedIndex = 0;
			changeProp(null);
		}
		
		private function changeProp(event:Event):void {
			var propId:String = propCombo.selectedLabel;
			
			var propImage:PropImage = catalog.retrievePropImage(propId);
			propBitmap.bitmapData = propImage.imageData;

			for (var i:int = 0; i < solidChoices.length; i++) {
				if (solidCombo.getItemAt(i).data == propImage.solid) {
					solidCombo.selectedIndex = i;
					break;
				}
			}
		}
		
		private function changeSolid(event:Event):void {
			var propId:String = propCombo.selectedLabel;
			var solid:uint = solidCombo.selectedItem.data;
			if (solid == Prop.SOLID) {
				catalog.deleteXmlAttribute(propId, "solid");
			} else {
				catalog.changeXmlAttribute(propId, "solid", "0x" + solid.toString(16));
			}
		}
		
	} // end class PropEditUI

}