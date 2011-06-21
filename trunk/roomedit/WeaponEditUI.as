package angel.roomedit {
	import angel.common.CatalogEntry;
	import angel.common.Defaults;
	import angel.common.SimplerButton;
	import angel.common.Util;
	import angel.common.WeaponResource;
	import fl.controls.CheckBox;
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
		private var typeCombo:ComboBox;
		private var weaponCombo:ComboBox;
		private var nameField:LabeledTextField;
		private var damageField:LabeledTextField;
		private var rangeField:LabeledTextField;
		private var cooldownField:LabeledTextField;
		private var ignoreUserGait:CheckBox;
		private var ignoreTargetGait:CheckBox;
		private var delayField:LabeledTextField;
		private var deleteFromCatalogButton:SimplerButton;
		
		private static const WIDTH:int = 220;
		private static const weaponTypes:Vector.<String> = Vector.<String>(["hand", "thrown"]);
		
		public function WeaponEditUI(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			
			weaponCombo = catalog.createChooser(CatalogEntry.WEAPON, WIDTH);
			weaponCombo.addEventListener(Event.CHANGE, changeWeapon);
			addChild(weaponCombo);
			
			var typeLabel:TextField = Util.textBox("Type:", 40);
			Util.addBelow(typeLabel, weaponCombo, 10);
			typeCombo = Util.createChooserFromStringList(weaponTypes, WIDTH-40, typeChangeListener);
			Util.addBeside(typeCombo, typeLabel);
			
			nameField = LabeledTextField.createBelow(typeCombo, "Display Name", 85, WIDTH-85,
					function(event:Event):void { changeWeaponProperty(event.target.text, "displayName", Defaults.GUN_DISPLAY_NAME) }, 0 );
			damageField = LabeledTextField.createBelow(nameField, "Damage", 85, 40,
					function(event:Event):void { changeWeaponProperty(int(event.target.text), "damage", Defaults.GUN_DAMAGE) } );
			rangeField = LabeledTextField.createBelow(damageField, "Range", 85, 40,
					function(event:Event):void { changeWeaponProperty(int(event.target.text), "range", Defaults.WEAPON_RANGE) } );
			cooldownField = LabeledTextField.createBelow(rangeField, "Cooldown", 85, 40,
					function(event:Event):void { changeWeaponProperty(int(event.target.text), "cooldown", Defaults.WEAPON_COOLDOWN) } );
			ignoreUserGait = Util.createCheckboxEditControlBelow(cooldownField, "Ignore User Gait", 120,
					function(event:Event):void { changeWeaponProperty( (event.target.selected ? true : false), "ignoreUserGait", false) } );
			ignoreTargetGait = Util.createCheckboxEditControlBelow(ignoreUserGait, "Ignore Target Gait", 120,
					function(event:Event):void { changeWeaponProperty( (event.target.selected ? true : false), "ignoreTargetGait", false) } );
			
			delayField = LabeledTextField.createBelow(damageField, "Delay", 85, 40,
					function(event:Event):void { changeWeaponProperty(int(event.target.text), "delay", 0) } );
					
					
			deleteFromCatalogButton = new SimplerButton("Delete from catalog", clickedDelete, 0xff0000);
			deleteFromCatalogButton.width = WIDTH;
			Util.addBelow(deleteFromCatalogButton, ignoreTargetGait, 50);
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
			nameField.text = resource.displayName;
			damageField.text = String(resource.damage);
			rangeField.text = String(resource.range);
			cooldownField.text = String(resource.cooldown);
			ignoreUserGait.selected = resource.ignoreUserGait;
			ignoreTargetGait.selected = resource.ignoreTargetGait;
			delayField.text = String(resource.delay);
			
			typeCombo.selectedItem = Util.itemWithLabelInComboBox(typeCombo, resource.type);
			hideOrShowControlsForType(resource.type);
		}
		
		private function typeChangeListener(event:Event):void {
			var type:String = typeCombo.selectedLabel;
			changeWeaponProperty(type, "type", Defaults.WEAPON_TYPE);
			
			//This will become increasingly clunky as the number of parameters grows, so we may switch to subclassing later
			changeWeaponProperty(Defaults.WEAPON_RANGE, "range", Defaults.WEAPON_RANGE);
			changeWeaponProperty(Defaults.WEAPON_COOLDOWN, "cooldown", Defaults.WEAPON_COOLDOWN);
			changeWeaponProperty(false, "ignoreUserGait", false);
			changeWeaponProperty(false, "ignoreTargetGait", false);
			changeWeaponProperty(0, "delay", 0);
			rangeField.text = String(Defaults.WEAPON_RANGE);
			cooldownField.text = String(Defaults.WEAPON_COOLDOWN);
			ignoreUserGait.selected = false;
			ignoreTargetGait.selected = false;
			delayField.text = String(0);
			hideOrShowControlsForType(type);
		}
		
		private function hideOrShowControlsForType(type:String):void {
			var isHand:Boolean = (type == "hand");
			rangeField.visible = cooldownField.visible = ignoreUserGait.visible = ignoreTargetGait.visible = isHand;
			delayField.visible = !isHand;
		}
		
		private function changeWeaponProperty(newValue:*, propertyName:String, defaultValue:* = null):void {
			var weaponId:String = weaponCombo.selectedLabel;
			var resource:WeaponResource = catalog.retrieveWeaponResource(weaponId);
			
			resource[propertyName] = newValue;
			if (newValue == defaultValue) {
				catalog.deleteXmlAttribute(weaponId, propertyName);
			} else {
				if (newValue is Boolean) {
					catalog.changeXmlAttribute(weaponId, propertyName, newValue ? "yes" : "no");
				} else {
					catalog.changeXmlAttribute(weaponId, propertyName, String(newValue));
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
			var weaponId:String = weaponCombo.selectedLabel;
			catalog.deleteCatalogEntry(weaponId);
			
			weaponCombo.removeItem(weaponCombo.selectedItem);
			weaponCombo.selectedIndex = 0;
			changeWeapon(null);
			CatalogEditUI.warnSaveCatalogAndRestart();
		}
		
	}

}