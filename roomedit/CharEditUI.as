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
		private var portraitBitmap:Bitmap;
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
		private var portraitFileControl:FilenameControl;
		private var deleteFromCatalogButton:SimplerButton;
		
		private static const COLUMN_WIDTH:int = 220;
		private static const COLUMN2_X:int = COLUMN_WIDTH + 20;
		private static const WIDTH:int = (COLUMN_WIDTH * 2) + 20;
		
		private static const PORTRAIT_MINI_WIDTH:int = 200;
		private static const PORTRAIT_MINI_HEIGHT:int = Prop.HEIGHT;
		
		private static const PORTRAIT_HEIGHT:int = 276;
		private static const PORTRAIT_WIDTH:int = 329;
		
		public function CharEditUI(catalog:CatalogEdit, startId:String = null) {
			this.catalog = catalog;
			if (labelFromAnimationClass == null) {
				initAnimationLabelLookup();
			}
			
			charIdCombo = catalog.createChooser(CatalogEntry.CHARACTER, COLUMN_WIDTH);
			charIdCombo.addEventListener(Event.CHANGE, changeChar);
			charIdCombo.x = (WIDTH - charIdCombo.width) /2;
			addChild(charIdCombo);
			
			var imageX:int = (COLUMN_WIDTH - Prop.WIDTH) / 2;
			var imageY:int = charIdCombo.y + charIdCombo.height + 5;
			
			graphics.lineStyle(1, 0, 1);
			graphics.moveTo(imageX, imageY - 1);
			graphics.lineTo(imageX + Prop.WIDTH, imageY - 1);
			var topButton:SimplerButton = new SimplerButton("Find Top", setTopByPixelScan);
			topButton.width = 70;
			topButton.x = imageX + Prop.WIDTH + 5;
			topButton.y = imageY;
			addChild(topButton);
			var resetTopButton:SimplerButton = new SimplerButton("Reset Top", resetTop);
			resetTopButton.width = 70;
			resetTopButton.x = topButton.x;
			resetTopButton.y = imageY + Prop.HEIGHT - resetTopButton.height;
			addChild(resetTopButton);
			animationTypeLabel = Util.textBox("");
			animationTypeLabel.y = imageY + Prop.HEIGHT - animationTypeLabel.height;
			addChild(animationTypeLabel);
			
			propBitmap = new Bitmap(new BitmapData(Prop.WIDTH, Prop.HEIGHT));
			propBitmap.x = imageX;
			propBitmap.y = imageY;
			addChild(propBitmap);
			
			portraitBitmap = new Bitmap(new BitmapData(PORTRAIT_WIDTH, PORTRAIT_HEIGHT, true, 0x00000000));
			portraitBitmap.scaleY = PORTRAIT_MINI_HEIGHT / PORTRAIT_HEIGHT;
			portraitBitmap.scaleX = portraitBitmap.scaleY;
			portraitBitmap.x = COLUMN2_X + (COLUMN_WIDTH - portraitBitmap.width) / 2;
			portraitBitmap.y = imageY;
			addChild(portraitBitmap);
			
			changeImageControl = FilenameControl.createBelow(propBitmap, false, "Image", 0, 220, changeFilename, 0);
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
			mainGunCombo = createWeaponChooserBelow(noSprintHackCheckbox, "Main Gun", 65, COLUMN_WIDTH-65,
					function(event:Event):void { changeCharacterProperty(mainGunCombo.selectedLabel, "mainGun", "") }, 0);
			offGunCombo = createWeaponChooserBelow(mainGunCombo, "Off Gun", 65, COLUMN_WIDTH-65,
					function(event:Event):void { changeCharacterProperty(offGunCombo.selectedLabel, "offGun", "") }, 0);
			inventoryTextField = Util.createTextEditControlBelow(offGunCombo, "Inv.", 30, COLUMN_WIDTH-30,
				function(event:Event):void { changeCharacterProperty(int(event.target.text), "inventory", "") }, 0 );
				
			portraitFileControl = new FilenameControl(true, "Portrait", COLUMN_WIDTH, 0);
			portraitFileControl.x = COLUMN2_X;
			portraitFileControl.y = changeImageControl.y;
			portraitFileControl.addEventListener(Event.CHANGE, changePortraitFile);
			addChild(portraitFileControl);
			
			deleteFromCatalogButton = new SimplerButton("Delete from catalog", clickedDelete, 0xff0000);
			deleteFromCatalogButton.width = COLUMN_WIDTH;
			Util.addBelow(deleteFromCatalogButton, inventoryTextField, 5);
			deleteFromCatalogButton.x = (WIDTH - deleteFromCatalogButton.width) /2;
			
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
			
			nameTextField.text = characterStats.displayName;
			healthTextField.text = String(characterStats.health);
			mainGunCombo.selectedItem = Util.itemWithLabelInComboBox(mainGunCombo, characterStats.mainGun);
			offGunCombo.selectedItem = Util.itemWithLabelInComboBox(offGunCombo, characterStats.offGun);
			movePointsTextField.text = String(characterStats.movePoints);
			actionsTextField.text = String(characterStats.actionsPerTurn);
			changeImageControl.text = catalog.getFilenameFromId(charId);
			noSprintHackCheckbox.selected = (characterStats.maxGait < 3);
			portraitFileControl.text = characterStats.portraitFile;
			inventoryTextField.text = String(characterStats.inventory);
		}
		
		private function changeCharacterProperty(newValue:*, propertyName:String, defaultValue:* = null, xmlAttribute:String = null):void {
			var charId:String = charIdCombo.selectedLabel;
			var characterStats:CharacterStats = catalog.retrieveCharacterResource(charId).characterStats;
			if (xmlAttribute == null) {
				xmlAttribute = propertyName;
			}
			
			characterStats[propertyName] = newValue;
			if (newValue == defaultValue) {
				catalog.deleteXmlAttribute(charId, xmlAttribute);
			} else {
				catalog.changeXmlAttribute(charId, xmlAttribute, String(newValue));
			}
			
			//UNDONE: temporary code to phase over catalog entries from before weapons existed
			if (propertyName == "mainGun") {
				catalog.deleteXmlAttribute(charId, "damage");
			}
		}
		
		private function createWeaponChooserBelow(previousControl:DisplayObject, labelText:String, labelWidth:int, fieldWidth:int, changeHandler:Function, optionalXInsteadOfAligning:int = int.MAX_VALUE):ComboBox {
			var weaponChooser:ComboBox = catalog.createChooser(CatalogEntry.WEAPON, fieldWidth);
			weaponChooser.addItemAt( { label:"" }, 0 );
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
			weaponChooser.addEventListener(Event.CHANGE, changeHandler);
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
		
		private function changePortraitFile(event:Event):void {
			var charId:String = charIdCombo.selectedLabel;
			var newFilename:String = portraitFileControl.text;
			changeCharacterProperty(newFilename, "portraitFile", "", "portrait");
			LoaderWithErrorCatching.LoadBytesFromFile(newFilename, updateToNewPortrait, charId);
		}
		
		private function updateToNewPortrait(event:Event, param:Object, filename:String):void {
			var charId:String = String(param);
			portraitBitmap.bitmapData = Bitmap(event.target.content).bitmapData;
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