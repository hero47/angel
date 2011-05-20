package angel.roomedit {
	import angel.common.Alert;
	import angel.common.Assert;
	import angel.common.CatalogEntry;
	import angel.common.CharacterStats;
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
		private var propCombo:ComboBox;
		private var healthTextField:TextField;
		private var damageTextField:TextField;
		private var movePointsTextField:TextField;
		private var nameTextField:TextField;
		private var changeImageControl:FilenameControl;
		private var noSprintHackCheckbox:CheckBox;
		
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
			
			var propChooser:ComboHolder = catalog.createChooser(CatalogEntry.CHARACTER, WIDTH);
			propChooser.comboBox.addEventListener(Event.CHANGE, changeProp);
			propChooser.y = propBitmap.y + propBitmap.height + 10;
			propCombo = propChooser.comboBox;
			addChild(propChooser);
			
			nameTextField = Util.createTextEditControlBelow(propChooser, "Display Name", 100, 100,
					function(event:Event):void { changeCharacterProperty(event.target.text, "displayName", Defaults.DISPLAY_NAME) }, 0);
			healthTextField = Util.createTextEditControlBelow(nameTextField, "Hits", 100, 40,
					function(event:Event):void { changeCharacterProperty(int(event.target.text), "health", Defaults.HEALTH) }, 0);
			damageTextField = Util.createTextEditControlBelow(healthTextField, "Damage", 100, 40,
					function(event:Event):void { changeCharacterProperty(int(event.target.text), "damage", Defaults.DAMAGE) }, 0);
			movePointsTextField = Util.createTextEditControlBelow(damageTextField, "Move Points", 100, 40,
					function(event:Event):void { changeCharacterProperty(int(event.target.text), "movePoints", Defaults.MOVE_POINTS) }, 0 );
			changeImageControl = FilenameControl.createBelow(movePointsTextField, false, "Image", 0, 220, changeFilename, 0);
			noSprintHackCheckbox = Util.createCheckboxEditControlBelow(changeImageControl, "No Sprint Hack", 120,
					function(event:Event):void { changeCharacterProperty( (event.target.selected ? 2 : 3), "maxGait", Defaults.MAX_GAIT) }, 0 );
			
			if (startId == null) {
				propCombo.selectedIndex = 0;
			} else {
				propCombo.selectedItem = Util.itemWithLabelInComboBox(propCombo, startId);
			}
			
			changeProp(null);
		}
		
		private function changeProp(event:Event):void {
			var charId:String = propCombo.selectedLabel;

			var resource:RoomContentResource = catalog.retrieveCharacterResource(charId);
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
			damageTextField.text = String(characterStats.damage);
			movePointsTextField.text = String(characterStats.movePoints);
			changeImageControl.text = catalog.getFilenameFromId(charId);
			noSprintHackCheckbox.selected = (characterStats.maxGait < 3);
		}
		
		private function changeCharacterProperty(newValue:*, propertyName:String, defaultValue:* = null):void {
			var charId:String = propCombo.selectedLabel;
			var characterStats:CharacterStats = catalog.retrieveCharacterResource(charId).characterStats;
			
			characterStats[propertyName] = newValue;
			if (newValue == defaultValue) {
				catalog.deleteXmlAttribute(charId, propertyName);
			} else {
				catalog.changeXmlAttribute(charId, propertyName, String(newValue));
			}
		}

		private function setTopByPixelScan(event:Event):void {
			var charId:String = propCombo.selectedLabel;
			
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
			var charId:String = propCombo.selectedLabel;
			catalog.deleteXmlAttribute(charId, "top");
			catalog.discardCachedData(charId);
			changeProp(null);
		}
		
		private function changeFilename(event:Event):void {
			var newFilename:String = changeImageControl.text;
			LoaderWithErrorCatching.LoadBytesFromFile(newFilename, updateToNewFilename);
		}
		
		private function updateToNewFilename(event:Event, filename:String):void {
			var bitmapData:BitmapData = Bitmap(event.target.content).bitmapData;
			var charId:String = propCombo.selectedLabel;
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
			if (propCombo.selectedLabel == charId) {
				changeProp(null);
			}
		}
		
		private function initAnimationLabelLookup():void {
			labelFromAnimationClass = new Dictionary();
			labelFromAnimationClass[SingleImageAnimation] = "(single image)";
			labelFromAnimationClass[SpinnerAnimation] = "(spinner)";
			labelFromAnimationClass[WalkerAnimation] = "(walker)";
			labelFromAnimationClass[null] = "(checking image file)";
		}
		
	} // end class PropEditUI

}