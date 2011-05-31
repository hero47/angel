package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Defaults;
	import angel.common.SimplerButton;
	import angel.common.Util;
	import angel.common.WeaponResource;
	import fl.controls.ComboBox;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class WeaponEditUI extends Sprite {
		private var catalog:CatalogEdit;
		private var weaponCombo:ComboBox;
		private var nameTextField:TextField;
		private var damageTextField:TextField;
		private var deleteFromCatalogButton:SimplerButton;
		
		private static const WIDTH:int = 220;
		
		public function WeaponEditUI(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			
			var weaponChooser:ComboHolder = catalog.createChooser(CatalogEntry.WEAPON, WIDTH);
			weaponChooser.comboBox.addEventListener(Event.CHANGE, changeWeapon);
			weaponCombo = weaponChooser.comboBox;
			addChild(weaponChooser);
			
			var weaponType:TextField = Util.textBox("Type: Fire at Character (Gun)", WIDTH); // This will probably be a chooser, someday
			Util.addBelow(weaponType, weaponChooser);
			nameTextField = Util.createTextEditControlBelow(weaponType, "Display Name", 80, 120,
					function(event:Event):void { changeWeaponProperty(event.target.text, "displayName", Defaults.GUN_DISPLAY_NAME) }, 0);
			damageTextField = Util.createTextEditControlBelow(nameTextField, "Damage", 80, 40,
					function(event:Event):void { changeWeaponProperty(int(event.target.text), "damage", Defaults.GUN_DAMAGE) }, 0);
			
			deleteFromCatalogButton = new SimplerButton("Delete from catalog", clickedDelete, 0xff0000);
			deleteFromCatalogButton.width = WIDTH;
			Util.addBelow(deleteFromCatalogButton, damageTextField, 50);
			deleteFromCatalogButton.x = 0;
			
			if (startId == null) {
				weaponCombo.selectedIndex = 0;
			} else {
				weaponCombo.selectedItem = Util.itemWithLabelInComboBox(weaponCombo, startId);
			}
			
			changeWeapon(null);
		}
		
		private function changeWeapon(event:Event):void {
			var weaponId:String = weaponCombo.selectedLabel;

			var resource:WeaponResource = catalog.retrieveWeaponResource(weaponId);
			nameTextField.text = resource.displayName;
			damageTextField.text = String(resource.damage);
		}
		
		private function changeWeaponProperty(newValue:*, propertyName:String, defaultValue:* = null):void {
			var weaponId:String = weaponCombo.selectedLabel;
			var resource:WeaponResource = catalog.retrieveWeaponResource(weaponId);
			
			resource[propertyName] = newValue;
			if (newValue == defaultValue) {
				catalog.deleteXmlAttribute(weaponId, propertyName);
			} else {
				catalog.changeXmlAttribute(weaponId, propertyName, String(newValue));
			}
		}
		
		private function clickedDelete(event:Event):void {
			CatalogEditUI.confirmDelete(deleteCallback);
		}
		
		private function deleteCallback(buttonClicked:String):void {
			if (buttonClicked != "Delete") {
				return;
			}
			var weaponId:String = weaponCombo.selectedLabel;
			catalog.deleteCatalogEntry(weaponId);
			
			weaponCombo.removeItem(weaponCombo.selectedItem);
			weaponCombo.selectedIndex = 0;
			changeWeapon(null);
			CatalogEditUI.warnSaveCatalogAndRestart();
		}
		
	}

}