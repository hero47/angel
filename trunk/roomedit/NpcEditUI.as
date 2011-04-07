package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Prop;
	import angel.common.PropImage;
	import angel.common.SimplerButton;
	import angel.common.Util;
	import angel.common.WalkerImage;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class NpcEditUI extends Sprite {

		private var catalog:CatalogEdit;
		private var propBitmap:Bitmap;
		private var propCombo:ComboBox;
		private var healthTextField:TextField;
		
		private static const WIDTH:int = 220;
		
		public function NpcEditUI(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			
			var imageX:int = (WIDTH - Prop.WIDTH) / 2;
			
			graphics.lineStyle(1, 0, 1);
			graphics.moveTo(imageX, 0);
			graphics.lineTo(imageX + Prop.WIDTH, 0);
			var topButton:SimplerButton = new SimplerButton("Top", setTopByPixelScan);
			topButton.width = 50;
			topButton.x = imageX + Prop.WIDTH + 5;
			addChild(topButton);
			var resetTopButton:SimplerButton = new SimplerButton("Reset", resetTop);
			resetTopButton.width = topButton.width;
			resetTopButton.x = topButton.x;
			resetTopButton.y = Prop.HEIGHT - resetTopButton.height;
			addChild(resetTopButton);
			
			propBitmap = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			propBitmap.x = imageX;
			propBitmap.y = 1;
			addChild(propBitmap);
			
			var propChooser:Sprite = catalog.createChooser(CatalogEntry.WALKER, WIDTH);
			propCombo = ComboBox(propChooser.getChildAt(0));
			propCombo.addEventListener(Event.CHANGE, changeProp);
			propChooser.y = propBitmap.y + propBitmap.height + 10;
			addChild(propChooser);
			
			var label:TextField = Util.textBox("Health:", 50, 20);
			label.y = propChooser.y + propCombo.height + 10;
			addChild(label);
			healthTextField = Util.textBox("", 40, 20, TextFormatAlign.LEFT, true);
			healthTextField.x = label.x + label.width + 5;
			healthTextField.y = label.y;
			healthTextField.addEventListener(Event.CHANGE, changeHealth);
			addChild(healthTextField);

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
			var walkerId:String = propCombo.selectedLabel;
			
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(walkerId);
			propBitmap.bitmapData = walkerImage.bitsFacing(WalkerImage.FACE_CAMERA);
			
			healthTextField.text = String(walkerImage.health);
		}
		
		private function changeHealth(event:Event):void {
			var walkerId:String = propCombo.selectedLabel;
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(walkerId);
			
			walkerImage.health = int(healthTextField.text);
			catalog.changeXmlAttribute(walkerId, "health", String(walkerImage.health));
		}
		
		private function setTopByPixelScan(event:Event):void {
			var walkerId:String = propCombo.selectedLabel;
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(walkerId);
			
			var blankRows:int = countBlankRowsAtTop(walkerImage);
			walkerImage.increaseTop(blankRows);
			
			catalog.changeXmlAttribute(walkerId, "top", String(walkerImage.unusedPixelsAtTopOfCell));
			trace("new top", walkerImage.unusedPixelsAtTopOfCell);
		}
		
		private function countBlankRowsAtTop(walkerImage:WalkerImage):int {
			var bits:BitmapData = walkerImage.bitsFacing(WalkerImage.FACE_CAMERA, WalkerImage.STAND);
			for (var y:int = 0; y < bits.rect.height; y++) {
				for (var x:int = 0; x < bits.rect.width; x++) {
					if (bits.getPixel32(x, y) != 0) {
						trace("first non-transparent bit at", x, y);
						return y;
					}
				}
			}
			return 0;
		}
		
		private function resetTop(event:Event):void {
			var walkerId:String = propCombo.selectedLabel;
			catalog.deleteXmlAttribute(walkerId, "top");
			catalog.discardCachedData(walkerId);
			changeProp(null);
		}
		
		
	} // end class PropEditUI

}