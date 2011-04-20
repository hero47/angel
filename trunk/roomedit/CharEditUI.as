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
	public class CharEditUI extends Sprite {

		private var catalog:CatalogEdit;
		private var propBitmap:Bitmap;
		private var propCombo:ComboBox;
		private var healthTextField:TextField;
		private var movePointsTextField:TextField;
		private var nameTextField:TextField;
		
		private static const WIDTH:int = 220;
		
		public function CharEditUI(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			
			var imageX:int = (WIDTH - Prop.WIDTH) / 2;
			
			graphics.lineStyle(1, 0, 1);
			graphics.moveTo(imageX, 0);
			graphics.lineTo(imageX + Prop.WIDTH, 0);
			var topButton:SimplerButton = new SimplerButton("Top", setTopByPixelScan);
			topButton.width = 50;
			topButton.x = imageX + Prop.WIDTH + 5;
			addChild(topButton);
			var resetTopButton:SimplerButton = new SimplerButton("Reset Top", resetTop);
			resetTopButton.width = 70;
			resetTopButton.x = topButton.x;
			resetTopButton.y = Prop.HEIGHT - resetTopButton.height;
			addChild(resetTopButton);
			
			var changeImageFileButton:SimplerButton = new SimplerButton("New Image", changeImage, 0x880000);
			changeImageFileButton.width = 80;
			changeImageFileButton.x = 0;
			changeImageFileButton.y = 0; // resetTopButton.y;
			addChild(changeImageFileButton);
			
			propBitmap = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			propBitmap.x = imageX;
			propBitmap.y = 1;
			addChild(propBitmap);
			
			var propChooser:ComboHolder = catalog.createChooser(CatalogEntry.WALKER, WIDTH);
			propChooser.comboBox.addEventListener(Event.CHANGE, changeProp);
			propChooser.y = propBitmap.y + propBitmap.height + 10;
			propCombo = propChooser.comboBox;
			addChild(propChooser);
			
			nameTextField = Util.addTextEditControl(this, propChooser, "Display Name", 100, 100,
					function(event:Event):void { changeWalkerImageProperty(event.target.text, "displayName") });
			healthTextField = Util.addTextEditControl(this, nameTextField, "Hits", 100, 40,
					function(event:Event):void { changeWalkerImageProperty(int(event.target.text), "health") });
			movePointsTextField = Util.addTextEditControl(this, healthTextField, "Move Points", 100, 40,
					function(event:Event):void { changeWalkerImageProperty(int(event.target.text), "movePoints") } );
			
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
			
			nameTextField.text = walkerImage.displayName;
			healthTextField.text = String(walkerImage.health);
			movePointsTextField.text = String(walkerImage.movePoints);
		}
		
		private function changeWalkerImageProperty(newValue:*, propertyName:String):void {
			var walkerId:String = propCombo.selectedLabel;
			var walkerImage:WalkerImage = catalog.retrieveWalkerImage(walkerId);
			
			walkerImage[propertyName] = newValue;
			catalog.changeXmlAttribute(walkerId, propertyName, String(newValue));
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
		
		private function changeImage(event:Event):void {
			new FileChooser(userSelectedNewCharFile, null, false);
		}
		
		private function userSelectedNewCharFile(filename:String):void {
			var walkerId:String = propCombo.selectedLabel;
			catalog.changeFilename(walkerId, filename);
		}
		
		
	} // end class PropEditUI

}