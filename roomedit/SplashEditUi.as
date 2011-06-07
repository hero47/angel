package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.SimplerButton;
	import angel.common.SplashResource;
	import angel.common.Util;
	import fl.controls.ComboBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class SplashEditUi extends Sprite {
		private var catalog:CatalogEdit;
		private var splashCombo:ComboBox;
		private var changeImageControl:FilenameControl;
		private var splashBitmap:Bitmap;
		
		private static const WIDTH:int = 220;
		
		public function SplashEditUi(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			splashBitmap = new Bitmap(new BitmapData(SplashResource.WIDTH, SplashResource.HEIGHT));
			splashBitmap.width /= 5;
			splashBitmap.height /= 5;
			splashBitmap.x = (WIDTH - splashBitmap.width) / 2;
			addChild(splashBitmap)
			
			var splashChooser:ComboHolder = catalog.createChooser(CatalogEntry.SPLASH, WIDTH);
			splashChooser.comboBox.addEventListener(Event.CHANGE, changeSplash);
			splashChooser.y = splashBitmap.y + splashBitmap.height + 10;
			splashCombo = splashChooser.comboBox;
			addChild(splashChooser);
			
			changeImageControl = FilenameControl.createBelow(splashChooser, false, "Image", 0, 220, changeFilename, 0);
			
			var deleteFromCatalogButton:SimplerButton = new SimplerButton("Delete from catalog", clickedDelete, 0xff0000);
			deleteFromCatalogButton.width = WIDTH;
			Util.addBelow(deleteFromCatalogButton, changeImageControl, 50);
			deleteFromCatalogButton.x = 0;
			
			if (startId == null) {
				splashCombo.selectedIndex = 0;
			} else {
				splashCombo.selectedItem = Util.itemWithLabelInComboBox(splashCombo, startId);
			}
			
			changeSplash(null);
		}
		
		private function changeSplash(event:Event):void {
			var splashId:String = splashCombo.selectedLabel;

			var resource:SplashResource = catalog.retrieveSplashResource(splashId);
			splashBitmap.bitmapData = resource.bitmapData;
			changeImageControl.text = catalog.getFilenameFromId(splashId);
		}
		
		private function changeFilename(event:Event):void {
			var newFilename:String = changeImageControl.text;
			LoaderWithErrorCatching.LoadBytesFromFile(newFilename, updateToNewFilename);
		}
		
		private function updateToNewFilename(event:Event, filename:String):void {
			var bitmapData:BitmapData = Bitmap(event.target.content).bitmapData;
			var splashId:String = splashCombo.selectedLabel;
			catalog.changeFilename(splashId, filename);
			changeSplash(null);
		}
		
		private function clickedDelete(event:Event):void {
			CatalogEditUI.confirmDelete(deleteCallback);
		}
		
		private function deleteCallback(buttonClicked:String):void {
			if (buttonClicked != "Delete") {
				return;
			}
			var splashId:String = splashCombo.selectedLabel;
			catalog.deleteCatalogEntry(splashId);
			
			splashCombo.removeItem(splashCombo.selectedItem);
			splashCombo.selectedIndex = 0;
			changeSplash(null);
			CatalogEditUI.warnSaveCatalogAndRestart();
		}
	}

}