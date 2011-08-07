package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Defaults;
	import angel.common.EvidenceResource;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.SimplerButton;
	import angel.common.Util;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.geom.Point;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	
	//UNDONE: This file duplicates lots from WeaponEditUI.  Should be able to combine them or factor out common elements.
	public class EvidenceEditUI extends Sprite {
		private var catalog:CatalogEdit;
		private var iconBitmap:Bitmap;
		private var imageBitmap:Bitmap;
		private var evidenceCombo:ComboBox;
		private var nameField:LabeledTextField;
		private var iconFileControl:FilenameControl;
		private var imageFileControl:FilenameControl;
		private var deleteFromCatalogButton:SimplerButton;
		
		private static const COLUMN_WIDTH:int = 220;
		private static const COLUMN2_X:int = COLUMN_WIDTH + 20;
		private static const WIDTH:int = (COLUMN_WIDTH * 2) + 20;
		
		public static const STANDARD_ICON_SIZE:int = 28;
		
		public function EvidenceEditUI(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			
			evidenceCombo = catalog.createChooser(CatalogEntry.EVIDENCE, COLUMN_WIDTH);
			evidenceCombo.addEventListener(Event.CHANGE, changeEvidence);
			addChild(evidenceCombo);
			evidenceCombo.x = (WIDTH - evidenceCombo.width) /2;
			
			iconBitmap = new Bitmap(new BitmapData(STANDARD_ICON_SIZE, STANDARD_ICON_SIZE));
			Util.addBelow(iconBitmap, evidenceCombo);
			iconBitmap.x = (COLUMN_WIDTH - STANDARD_ICON_SIZE) / 2;
			iconBitmap.y += (EvidenceResource.IMAGE_HEIGHT - STANDARD_ICON_SIZE) / 2;
			
			imageBitmap = new Bitmap(new BitmapData(EvidenceResource.IMAGE_WIDTH, EvidenceResource.IMAGE_HEIGHT, true, 0x00000000));
			Util.addBelow(imageBitmap, evidenceCombo);
			imageBitmap.x = COLUMN2_X + (COLUMN_WIDTH - imageBitmap.width) / 2;
			
			iconFileControl = FilenameControl.createBelow(imageBitmap, true, "Icon", 0, 220, changeFilename, 0);
			imageFileControl = FilenameControl.createBelow(imageBitmap, true, "Image", 0, 220, changeImageFile, COLUMN2_X);
			
			nameField = LabeledTextField.createBelow(iconFileControl, "Display Name", 85, COLUMN_WIDTH-85,
					function(event:Event):void { changeEvidenceProperty(event.target.text, "displayName", "") }, 0 );
					
			deleteFromCatalogButton = new SimplerButton("Delete from catalog", clickedDelete, 0xff0000);
			deleteFromCatalogButton.width = WIDTH;
			Util.addBelow(deleteFromCatalogButton, iconFileControl, 50);
			deleteFromCatalogButton.x = 0;
			
			if (startId == null) {
				evidenceCombo.selectedIndex = 0;
			} else {
				evidenceCombo.selectedItem = Util.itemWithLabelInComboBox(evidenceCombo, startId);
			}
			
			changeEvidence(null);
		}
		
		private function changeEvidence(event:Event):void {
			var evidenceId:String = evidenceCombo.selectedLabel;

			var resource:EvidenceResource = EvidenceResource(catalog.retrieveInventoryResource(evidenceId));
			iconBitmap.bitmapData = resource.iconBitmapData;
			iconFileControl.text = catalog.getFilenameFromId(evidenceId);
			nameField.text = resource.displayName;
			imageBitmap.bitmapData = resource.imageBitmapData;
			imageFileControl.text = resource.imageFile;
		}
		
		private function changeEvidenceProperty(newValue:*, propertyName:String, defaultValue:* = null):void {
			var evidenceId:String = evidenceCombo.selectedLabel;
			var resource:EvidenceResource = EvidenceResource(catalog.retrieveInventoryResource(evidenceId));
			
			resource[propertyName] = newValue;
			if (newValue == defaultValue) {
				catalog.deleteXmlAttribute(evidenceId, propertyName);
			} else {
				if (newValue is Boolean) {
					catalog.changeXmlAttribute(evidenceId, propertyName, newValue ? "yes" : "no");
				} else {
					catalog.changeXmlAttribute(evidenceId, propertyName, String(newValue));
				}
			}
		}
		
		private function clickedDelete(event:Event):void {
			CatalogEditUI.confirmDelete(deleteCallback);
		}
		
		private function deleteCallback(buttonClicked:String):void {
			if (buttonClicked != "Delete") {
				return;
			}
			var evidenceId:String = evidenceCombo.selectedLabel;
			catalog.deleteCatalogEntry(evidenceId);
			
			evidenceCombo.removeItem(evidenceCombo.selectedItem);
			evidenceCombo.selectedIndex = 0;
			changeEvidence(null);
			CatalogEditUI.warnSaveCatalogAndRestart();
		}
		
		private function changeFilename(event:Event):void {
			var evidenceId:String = evidenceCombo.selectedLabel;
			var newFilename:String = iconFileControl.text;
			if (newFilename == "") {
				catalog.changeFilename(evidenceId, newFilename);
				changeEvidence(null);
			} else {
				LoaderWithErrorCatching.LoadBytesFromFile(newFilename, updateToNewFilename, evidenceId);
			}
		}
		
		private function updateToNewFilename(event:Event, param:Object, filename:String):void {
			var evidenceId:String = String(param);
			iconBitmap.bitmapData = Bitmap(event.target.content).bitmapData;
			catalog.changeFilename(evidenceId, filename);
		}
		
		private function changeImageFile(event:Event):void {
			var evidenceId:String = evidenceCombo.selectedLabel;
			var newFilename:String = imageFileControl.text;
			changeEvidenceProperty(newFilename, "imageFile", "");
			LoaderWithErrorCatching.LoadBytesFromFile(newFilename, updateToNewImage, evidenceId);
		}
		
		private function updateToNewImage(event:Event, param:Object, filename:String):void {
			var evidenceId:String = String(param);
			imageBitmap.bitmapData = Bitmap(event.target.content).bitmapData;
		}
		
	}

}