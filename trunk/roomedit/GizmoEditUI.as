package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Defaults;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.SimplerButton;
	import angel.common.Util;
	import angel.common.GizmoResource;
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
	public class GizmoEditUI extends Sprite {
		private var catalog:CatalogEdit;
		private var iconBitmap:Bitmap;
		private var typeCombo:ComboBox;
		private var gizmoCombo:ComboBox;
		private var nameField:LabeledTextField;
		private var valueField:LabeledTextField;
		private var changeImageControl:FilenameControl;
		private var deleteFromCatalogButton:SimplerButton;
		
		private static const WIDTH:int = 220;
		private static const gizmoTypes:Vector.<String> = Vector.<String>(["medpack"]);
		
		public static const STANDARD_ICON_SIZE:int = 28;
		
		public function GizmoEditUI(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			
			iconBitmap = new Bitmap(new BitmapData(STANDARD_ICON_SIZE, STANDARD_ICON_SIZE));
			iconBitmap.x = (WIDTH - STANDARD_ICON_SIZE) / 2;
			addChild(iconBitmap);
			
			gizmoCombo = catalog.createChooser(CatalogEntry.GIZMO, WIDTH);
			gizmoCombo.addEventListener(Event.CHANGE, changeGizmo);
			gizmoCombo.y = iconBitmap.y + iconBitmap.height + 10;
			addChild(gizmoCombo);
			
			var typeLabel:TextField = Util.textBox("Type:", 40);
			Util.addBelow(typeLabel, gizmoCombo, 10);
			typeCombo = Util.createChooserFromStringList(gizmoTypes, WIDTH-40, typeChangeListener);
			Util.addBeside(typeCombo, typeLabel);
			
			nameField = LabeledTextField.createBelow(typeCombo, "Display Name", 85, WIDTH-85,
					function(event:Event):void { changeGizmoProperty(event.target.text, "displayName", typeCombo.selectedLabel) }, 0 );
			valueField = LabeledTextField.createBelow(nameField, "Value", 85, 40,
					function(event:Event):void { changeGizmoProperty(int(event.target.text), "value", 0) } );
			changeImageControl = FilenameControl.createBelow(valueField, true, "Icon", 0, 220, changeFilename, 0);
					
			deleteFromCatalogButton = new SimplerButton("Delete from catalog", clickedDelete, 0xff0000);
			deleteFromCatalogButton.width = WIDTH;
			Util.addBelow(deleteFromCatalogButton, changeImageControl, 50);
			deleteFromCatalogButton.x = 0;
			
			if (startId == null) {
				gizmoCombo.selectedIndex = 0;
			} else {
				gizmoCombo.selectedItem = Util.itemWithLabelInComboBox(gizmoCombo, startId);
			}
			
			changeGizmo(null);
		}
		
		private function changeGizmo(event:Event):void {
			var gizmoId:String = gizmoCombo.selectedLabel;

			var resource:GizmoResource = GizmoResource(catalog.retrieveInventoryResource(gizmoId));
			iconBitmap.bitmapData = resource.iconBitmapData;
			changeImageControl.text = catalog.getFilenameFromId(gizmoId);
			nameField.text = resource.displayName;
			valueField.text = String(resource.value);
			
			typeCombo.selectedItem = Util.itemWithLabelInComboBox(typeCombo, resource.type);
			hideOrShowControlsForType(resource.type);
		}
		
		private function typeChangeListener(event:Event):void {
			var type:String = typeCombo.selectedLabel;
			changeGizmoProperty(type, "type", "");
			
			hideOrShowControlsForType(type);
		}
		
		private function hideOrShowControlsForType(type:String):void {
			// nothing here yet since only type is medpack
		}
		
		private function changeGizmoProperty(newValue:*, propertyName:String, defaultValue:* = null):void {
			var gizmoId:String = gizmoCombo.selectedLabel;
			var resource:GizmoResource = GizmoResource(catalog.retrieveInventoryResource(gizmoId));
			
			resource[propertyName] = newValue;
			if (newValue == defaultValue) {
				catalog.deleteXmlAttribute(gizmoId, propertyName);
			} else {
				if (newValue is Boolean) {
					catalog.changeXmlAttribute(gizmoId, propertyName, newValue ? "yes" : "no");
				} else {
					catalog.changeXmlAttribute(gizmoId, propertyName, String(newValue));
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
			var gizmoId:String = gizmoCombo.selectedLabel;
			catalog.deleteCatalogEntry(gizmoId);
			
			gizmoCombo.removeItem(gizmoCombo.selectedItem);
			gizmoCombo.selectedIndex = 0;
			changeGizmo(null);
			CatalogEditUI.warnSaveCatalogAndRestart();
		}
		
		private function changeFilename(event:Event):void {
			var gizmoId:String = gizmoCombo.selectedLabel;
			var newFilename:String = changeImageControl.text;
			if (newFilename == "") {
				catalog.changeFilename(gizmoId, newFilename);
				changeGizmo(null);
			} else {
				LoaderWithErrorCatching.LoadBytesFromFile(newFilename, updateToNewFilename, gizmoId);
			}
		}
		
		private function updateToNewFilename(event:Event, param:Object, filename:String):void {
			var gizmoId:String = String(param);
			iconBitmap.bitmapData = Bitmap(event.target.content).bitmapData;
			catalog.changeFilename(gizmoId, filename);
		}
		
	}

}