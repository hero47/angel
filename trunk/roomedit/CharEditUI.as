package angel.roomedit {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.CatalogEntry;
	import angel.common.CharacterStats;
	import angel.common.CharResource;
	import angel.common.Defaults;
	import angel.common.LoaderWithErrorCatching;
	import angel.common.Prop;
	import angel.common.RoomContentResource;
	import angel.common.SimplerButton;
	import angel.common.SingleImageAnimation;
	import angel.common.SpinnerAnimation;
	import angel.common.UnknownAnimationData;
	import angel.common.Util;
	import angel.common.WalkerAnimation;
	import angel.common.WalkerAnimationData;
	import fl.controls.CheckBox;
	import fl.controls.ComboBox;
	import flash.display.Bitmap;
	import flash.display.BitmapData;
	import flash.display.DisplayObject;
	import flash.display.Sprite;
	import flash.events.Event;
	import flash.text.TextField;
	import flash.text.TextFormatAlign;
	import flash.utils.Dictionary;
	/**
	 * ...
	 * @author Beth Moursund
	 */
	public class CharEditUI extends Sprite {
		
		private static var labelFromAnimationClass:Dictionary;

		private var catalog:CatalogEdit;
		private var propBitmap:Bitmap;
		private var animationTypeLabel:TextField;
		private var charIdCombo:ComboBox;
		private var healthTextField:TextField;
		private var damageTextField:TextField;
		private var mainGunCombo:ComboBox;
		private var offGunCombo:ComboBox;
		private var actionsTextField:TextField;
		private var movePointsTextField:TextField;
		private var nameTextField:TextField;
		private var changeImageControl:FilenameControl;
		private var noSprintHackCheckbox:CheckBox;
		private var inventoryTextField:TextField;
		private var deleteFromCatalogButton:SimplerButton;
		
		private static const WIDTH:int = 220;
		
		public function CharEditUI(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			if (labelFromAnimationClass == null) {
				initAnimationLabelLookup();
			}
			
			var imageX:int = (WIDTH - Prop.WIDTH) / 2;
			
			graphics.lineStyle(1, 0, 1);
			graphics.moveTo(imageX, 0);
			graphics.lineTo(imageX + Prop.WIDTH, 0);
			var topButton:SimplerButton = new SimplerButton("Find Top", setTopByPixelScan);
			topButton.width = 70;
			topButton.x = imageX + Prop.WIDTH + 5;
			addChild(topButton);
			var resetTopButton:SimplerButton = new SimplerButton("Reset Top", resetTop);
			resetTopButton.width = 70;
			resetTopButton.x = topButton.x;
			resetTopButton.y = Prop.HEIGHT - resetTopButton.height;
			addChild(resetTopButton);
			animationTypeLabel = Util.textBox("");
			animationTypeLabel.y = Prop.HEIGHT - animationTypeLabel.height;
			addChild(animationTypeLabel);
			
			propBitmap = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			propBitmap.x = imageX;
			propBitmap.y = 1;
			addChild(propBitmap);
			
			var charChooser:ComboHolder = catalog.createChooser(CatalogEntry.CHARACTER, WIDTH);
			charChooser.comboBox.addEventListener(Event.CHANGE, changeChar);
			charChooser.y = propBitmap.y + propBitmap.height + 10;
			charIdCombo = charChooser.comboBox;
			addChild(charChooser);
			
			changeImageControl = FilenameControl.createBelow(charChooser, false, "Image", 0, 220, changeFilename, 0);
			nameTextField = Util.createTextEditControlBelow(changeImageControl, "Display Name", 100, 100,
					function(event:Event):void { changeCharacterProperty(event.target.text, "displayName", Defaults.CHARACTER_DISPLAY_NAME) }, 0);
			healthTextField = Util.createTextEditControlBelow(nameTextField, "Hits", 100, 40,
					function(event:Event):void { changeCharacterProperty(int(event.target.text), "health", Defaults.CHARACTER_HEALTH) }, 0);
			actionsTextField = Util.createTextEditControlBelow(healthTextField, "Actions", 100, 40,
					function(event:Event):void { changeCharacterProperty(int(event.target.text), "actions", Defaults.ACTIONS_PER_TURN) }, 0 );
			movePointsTextField = Util.createTextEditControlBelow(actionsTextField, "Move Points", 100, 40,
					function(event:Event):void { changeCharacterProperty(int(event.target.text), "movePoints", Defaults.MOVE_POINTS) }, 0 );
			noSprintHackCheckbox = Util.createCheckboxEditControlBelow(movePointsTextField, "No Sprint Hack", 120,
					function(event:Event):void { changeCharacterProperty( (event.target.selected ? 2 : 3), "maxGait", Defaults.MAX_GAIT) }, 0 );
			var weaponChooser:ComboHolder = createWeaponChooserBelow(noSprintHackCheckbox, "Main Gun", 65, WIDTH-65,
					function(event:Event):void { changeCharacterProperty(mainGunCombo.selectedLabel, "mainGun", "") }, 0);
			mainGunCombo = weaponChooser.comboBox;
			weaponChooser = createWeaponChooserBelow(weaponChooser, "Off Gun", 65, WIDTH-65,
					function(event:Event):void { changeCharacterProperty(offGunCombo.selectedLabel, "offGun", "") }, 0);
			offGunCombo = weaponChooser.comboBox;
			inventoryTextField = Util.createTextEditControlBelow(weaponChooser, "Inv.", 30, WIDTH-30,
				function(event:Event):void { changeCharacterProperty(int(event.target.text), "inventory", "") }, 0 );
			
			deleteFromCatalogButton = new SimplerButton("Delete from catalog", clickedDelete, 0xff0000);
			deleteFromCatalogButton.width = WIDTH;
			Util.addBelow(deleteFromCatalogButton, inventoryTextField, 50);
			deleteFromCatalogButton.x = 0;
			
			if (startId == null) {
				charIdCombo.selectedIndex = 0;
			} else {
				charIdCombo.selectedItem = Util.itemWithLabelInComboBox(charIdCombo, startId);
			}
			
			changeChar(null);
		}
		
		private function changeChar(event:Event):void {
			var charId:String = charIdCombo.selectedLabel;

			var resource:CharResource = catalog.retrieveCharacterResource(charId);
			propBitmap.bitmapData = resource.standardImage();
			var animationClass:Class = resource.animationData.animationClass;
			if (animationClass == null) {
				Assert.assertTrue(resource.animationData is UnknownAnimationData, "Something's badly screwed up");
				UnknownAnimationData(resource.animationData).askForCallback(setAnimationTypeFromImageSize, charId);
			}
			animationTypeLabel.text = labelFromAnimationClass[animationClass];
			
			var characterStats:CharacterStats = resource.characterStats;
			
			//UNDONE remove this when files have been updated
			if (characterStats.grenades > 0) {
				catalog.deleteXmlAttribute(charId, "grenades");
				characterStats.inventory = String(characterStats.grenades) + " grenade";
				catalog.changeXmlAttribute(charId, "inventory", characterStats.inventory);
				characterStats.grenades = 0;
			}
			
			nameTextField.text = characterStats.displayName;
			healthTextField.text = String(characterStats.health);
			mainGunCombo.selectedItem = Util.itemWithLabelInComboBox(mainGunCombo, characterStats.mainGun);
			offGunCombo.selectedItem = Util.itemWithLabelInComboBox(offGunCombo, characterStats.offGun);
			movePointsTextField.text = String(characterStats.movePoints);
			actionsTextField.text = String(characterStats.actionsPerTurn);
			changeImageControl.text = catalog.getFilenameFromId(charId);
			noSprintHackCheckbox.selected = (characterStats.maxGait < 3);
			inventoryTextField.text = String(characterStats.inventory);
			
		}
		
		private function changeCharacterProperty(newValue:*, propertyName:String, defaultValue:* = null):void {
			var charId:String = charIdCombo.selectedLabel;
			var characterStats:CharacterStats = catalog.retrieveCharacterResource(charId).characterStats;
			
			characterStats[propertyName] = newValue;
			if (newValue == defaultValue) {
				catalog.deleteXmlAttribute(charId, propertyName);
			} else {
				catalog.changeXmlAttribute(charId, propertyName, String(newValue));
			}
			
			//UNDONE: temporary code to phase over catalog entries from before weapons existed
			if (propertyName == "mainGun") {
				catalog.deleteXmlAttribute(charId, "damage");
			}
		}
		
		private function createWeaponChooserBelow(previousControl:DisplayObject, labelText:String, labelWidth:int, fieldWidth:int, changeHandler:Function, optionalXInsteadOfAligning:int = int.MAX_VALUE):ComboHolder {
			var weaponChooser:ComboHolder = catalog.createChooser(CatalogEntry.WEAPON, fieldWidth);
			weaponChooser.comboBox.addItemAt( { label:"" }, 0 );
			if (labelText != null) {
				var label:TextField = Util.textBox(labelText + ":", labelWidth);
				Util.addBelow(label, previousControl, 5);
				if (optionalXInsteadOfAligning != int.MAX_VALUE) {
					label.x = optionalXInsteadOfAligning;
				}
				Util.addBeside(weaponChooser, label, 5);
			} else {
				Util.addBelow(weaponChooser, previousControl, 5);
				if (optionalXInsteadOfAligning != int.MAX_VALUE) {
					weaponChooser.x = optionalXInsteadOfAligning;
				}
			}
			weaponChooser.comboBox.addEventListener(Event.CHANGE, changeHandler);
			return weaponChooser;
		}

		private function setTopByPixelScan(event:Event):void {
			var charId:String = charIdCombo.selectedLabel;
			
			var resource:RoomContentResource = catalog.retrieveCharacterResource(charId);
			
			var blankRows:int = countBlankRowsAtTop(resource.standardImage());
			var newUnusedPixels:int = resource.animationData.increaseTop(blankRows);
			resource.unusedPixelsAtTopOfCell = newUnusedPixels;
			
			catalog.changeXmlAttribute(charId, "top", String(newUnusedPixels));
		}
		
		private function countBlankRowsAtTop(bits:BitmapData):int {
			for (var y:int = 0; y < bits.rect.height; y++) {
				for (var x:int = 0; x < bits.rect.width; x++) {
					if (bits.getPixel32(x, y) != 0) {
						return y;
					}
				}
			}
			return 0;
		}
		
		private function resetTop(event:Event):void {
			var charId:String = charIdCombo.selectedLabel;
			catalog.deleteXmlAttribute(charId, "top");
			catalog.discardCachedData(charId);
			changeChar(null);
		}
		
		private function changeFilename(event:Event):void {
			var charId:String = charIdCombo.selectedLabel;
			var newFilename:String = changeImageControl.text;
			LoaderWithErrorCatching.LoadBytesFromFile(newFilename, updateToNewFilename, charId);
		}
		
		private function updateToNewFilename(event:Event, param:Object, filename:String):void {
			var charId:String = String(param);
			var bitmapData:BitmapData = Bitmap(event.target.content).bitmapData;
			catalog.deleteXmlAttribute(charId, "top");
			catalog.changeFilename(charId, filename);
			setAnimationTypeFromImageSize(charId, bitmapData.width, bitmapData.height, filename);
		}
		
		//NOTE: clears catalog cache for this id, forcing RoomContentResource to be recreated, which will reload file
		//and create appropriate AnimationData based on the new @animate
		private function setAnimationTypeFromImageSize(charId:String, width:int, height:int, filename:String):void {
			var animationName:String;
			
			if ((width == Prop.WIDTH * 9) && (height == Prop.HEIGHT * 3)) {
				animationName = "walker";
			} else if ((width == Prop.WIDTH * 9) && (height == Prop.HEIGHT)) {
				animationName = "spinner";
			} else if ((width == Prop.WIDTH) && (height == Prop.HEIGHT)) {
				animationName = "single";
			} else {
				Alert.show("Warning! " + filename + "\nImage size does not match a known animation type.\nAssuming single image.");
				animationName = "single";
			}
			
			catalog.changeXmlAttribute(charId, "animate", animationName);
			catalog.discardCachedData(charId);
			if (charIdCombo.selectedLabel == charId) {
				changeChar(null);
			}
		}
		
		private function initAnimationLabelLookup():void {
			labelFromAnimationClass = new Dictionary();
			labelFromAnimationClass[SingleImageAnimation] = "(single image)";
			labelFromAnimationClass[SpinnerAnimation] = "(spinner)";
			labelFromAnimationClass[WalkerAnimation] = "(walker)";
			labelFromAnimationClass[null] = "(checking image file)";
		}
		
		private function clickedDelete(event:Event):void {
			CatalogEditUI.confirmDelete(deleteCallback);
		}
		
		private function deleteCallback(buttonClicked:String):void {
			if (buttonClicked != "Delete") {
				return;
			}
			var charId:String = charIdCombo.selectedLabel;
			catalog.deleteCatalogEntry(charId);
			
			charIdCombo.removeItem(charIdCombo.selectedItem);
			charIdCombo.selectedIndex = 0;
			changeChar(null);
			CatalogEditUI.warnSaveCatalogAndRestart();
		}
		
	} // end class PropEditUI

}